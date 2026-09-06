-- macros/scd_type_2.sql
{% macro scd_type_2(source_schema, source_table, target_schema, target_table, business_key, load_id_column='created_load_id', exclude_cols=[]) %}

    {% set relation = adapter.get_relation(
        database=target.database,
        schema=source_schema,
        identifier=source_table
    ) %}

    {% set columns = adapter.get_columns_in_relation(relation) %}

    {% set concat_expr = [] %}
    {% for col in columns %}
        {% if col.name|lower not in exclude_cols|map('lower') and col.name|lower != business_key|lower and col.name|lower != load_id_column|lower %}
            {% set dtype = col.data_type | lower %}
            {% if 'char' in dtype or 'text' in dtype or 'string' in dtype %}
                {% do concat_expr.append("coalesce(trim(" ~ col.name ~ "), '^')") %}
            {% else %}
                {% do concat_expr.append("coalesce(" ~ col.name ~ "::string, '^')") %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {% set sql %}
        merge into {{ target_schema }}.{{ target_table }} as tgt
        using (
            select
                {{ business_key }},
                {{ load_id_column }},
                md5({{ concat_expr | join(" || '|' || ") }}) as hash_diff,
                current_timestamp() as CREATED_DATE_TIME,
            from {{ source_schema }}.{{ source_table }}
        ) as src
        on tgt.{{ business_key }} = src.{{ business_key }}
        when matched and tgt.hash_diff <> src.hash_diff and tgt.is_current = true then
            update set tgt.is_current = false,
                       tgt.UPDATED_DATE_TIME = current_timestamp()
        when not matched then
            insert (
                {{ business_key }},
                {{ load_id_column }},
                hash_diff,
                CREATED_DATE_TIME,
                UPDATED_DATE_TIME,
                is_current
            )
            values (
                src.{{ business_key }},
                src.{{ load_id_column }},
                src.hash_diff,
                src.CREATED_DATE_TIME,
                null,
                true
            );
    {% endset %}

    {{ return(sql) }}

{% endmacro %}