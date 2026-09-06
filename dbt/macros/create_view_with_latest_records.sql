-- macros/create_view_with_latest_records.sql
{% macro create_view_with_latest_records(source_schema, source_table, target_schema, view_name, delta_column) %}

{% set relation = adapter.get_relation(
        database=target.database,
        schema=source_schema,
        identifier=source_table
    ) %}

    {% set columns = adapter.get_columns_in_relation(relation) %}

    {% set cleansed_columns = [] %}
    {% set concat_expr = [] %}
    {% for col in columns %}
        {% set dtype = col.data_type | lower %}
        {% if 'char' in dtype or 'text' in dtype or 'string' in dtype %}
            {% do cleansed_columns.append("trim(" ~ col.name ~ ") as " ~ col.name) %}
            {% do concat_expr.append("coalesce(trim(" ~ col.name ~ "), '^')") %}
        {% elif 'number' in dtype or 'int' in dtype or 'decimal' in dtype or 'float' in dtype %}
            {% do cleansed_columns.append("cast(" ~ col.name ~ " as number(38,10)) as " ~ col.name) %}
            {% do concat_expr.append("coalesce(cast(" ~ col.name ~ " as string), '^')") %}
        {% else %}
            {% do cleansed_columns.append(col.name) %}
            {% do concat_expr.append("coalesce(" ~ col.name ~ "::string, '^')") %}
        {% endif %}
    {% endfor %}

    {% set sql %}
        
        with cleansed as (
            select distinct
                {{ cleansed_columns | join(',\n    ') }},
                md5({{ concat_expr | join(" || '|' || ") }}) as hash_diff
            from {{ source_schema }}.{{ source_table }}
            where {{ delta_column }} is not null
        )
        select *
        from cleansed
        where {{ delta_column }} = (
            select max({{ delta_column }})
            from cleansed
        )
    {% endset %}

    {{ return(sql) }}

{% endmacro %}
