{% macro create_latest_view(raw_view_ref, delta_column, primary_key=none) %}

    {% set relation = ref(raw_view_ref) %}
    {% set columns = adapter.get_columns_in_relation(relation) %}

    {% set cleansed_columns = [] %}
    {% set concat_expr = [] %}

    {% for col in columns %}
        {% set dtype = col.data_type | lower %}

        {% if 'char' in dtype or 'text' in dtype or 'string' in dtype %}
            {% do cleansed_columns.append("trim(" ~ col.name ~ ") as " ~ col.name) %}
            {% do concat_expr.append("coalesce(trim(" ~ col.name ~ "), '^')") %}
        {% elif 'number' in dtype or 'int' in dtype %}
            {% do cleansed_columns.append("cast(" ~ col.name ~ " as number(38,0)) as " ~ col.name) %}
            {% do concat_expr.append("coalesce(cast(" ~ col.name ~ " as string), '^')") %}
        {% elif 'decimal' in dtype or 'float' in dtype %}
            {% do cleansed_columns.append("cast(" ~ col.name ~ " as number(38,10)) as " ~ col.name) %}
            {% do concat_expr.append("coalesce(cast(" ~ col.name ~ " as string), '^')") %}
        {% else %}
            {% do cleansed_columns.append(col.name) %}
            {% do concat_expr.append("coalesce(" ~ col.name ~ "::string, '^')") %}
        {% endif %}
    {% endfor %}

    with cleansed as (
        select
            {{ cleansed_columns | join(',\n            ') }},
            md5({{ concat_expr | join(" || '|' || ") }}) as hash_diff
        from {{ relation }}
        where {{ delta_column }} is not null
    ),

    latest_batch as (
        select *
        from cleansed
        where {{ delta_column }} = (
            select max({{ delta_column }})
            from cleansed
        )
    )

    {% if primary_key is not none %}
    , deduped as (
        select *,
            row_number() over (
                partition by {{ primary_key }}
                order by {{ delta_column }} desc, hash_diff
            ) as rn
        from latest_batch
    )

    select
        {% for col in columns %}
        {{ col.name }},
        {% endfor %}
        hash_diff
    from deduped
    where rn = 1

    {% else %}

    select distinct *
    from latest_batch

    {% endif %}

{% endmacro %}
