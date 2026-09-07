{% macro scd_type_2(source_schema, source_table, target_schema, target_table, business_keys=[], exclude_cols=[]) %}

    {% set relation = adapter.get_relation(
        database=target.database,
        schema=source_schema,
        identifier=source_table
    ) %}

    {% set columns = adapter.get_columns_in_relation(relation) %}

    {% set concat_expr = [] %}
    {% for col in columns %}
        {% if col.name|lower not in exclude_cols|map('lower')
              and col.name|lower not in business_keys|map('lower') %}
            {% set dtype = col.data_type | lower %}
            {% if 'char' in dtype or 'text' in dtype or 'string' in dtype %}
                {% do concat_expr.append("coalesce(trim(" ~ col.name ~ "), '^')") %}
            {% else %}
                {% do concat_expr.append("coalesce(" ~ col.name ~ "::string, '^')") %}
            {% endif %}
        {% endif %}
    {% endfor %}

    {% if concat_expr | length > 0 %}
        {% set hash_expr = "md5(" ~ concat_expr | join(" || '|' || ") ~ ")" %}
    {% else %}
        {% set hash_expr = "'NO_COLUMNS'" %}
    {% endif %}

    {% set sql %}
        merge into {{ target_schema }}.{{ target_table }} as tgt
        using (
            select
                {% for key in business_keys %}
                    {{ key }},
                {% endfor %}
                {% for col in columns %}
                    {% if col.name|lower not in exclude_cols|map('lower')
                          and col.name|lower not in business_keys|map('lower') %}
                        {{ col.name }},
                    {% endif %}
                {% endfor %}
                {{ hash_expr }} as hash_diff
            from {{ source_schema }}.{{ source_table }}
        ) as src
        on {% for key in business_keys %}
               tgt.{{ key }} = src.{{ key }}
               {% if not loop.last %} and {% endif %}
           {% endfor %}
        when matched and tgt.hash_diff <> src.hash_diff and tgt.is_current = true then
            update set tgt.is_current = false,
                       tgt.UPDATED_DATE_TIME = current_timestamp()
        when not matched then
            insert (
                {% for key in business_keys %}
                    {{ key }},
                {% endfor %}
                {% for col in columns %}
                    {% if col.name|lower not in exclude_cols|map('lower')
                          and col.name|lower not in business_keys|map('lower') %}
                        {{ col.name }},
                    {% endif %}
                {% endfor %}
                hash_diff,
                CREATED_DATE_TIME,
                UPDATED_DATE_TIME,
                is_current
            )
            values (
                {% for key in business_keys %}
                    src.{{ key }},
                {% endfor %}
                {% for col in columns %}
                    {% if col.name|lower not in exclude_cols|map('lower')
                          and col.name|lower not in business_keys|map('lower') %}
                        src.{{ col.name }},
                    {% endif %}
                {% endfor %}
                src.hash_diff,
                current_timestamp(),
                null,
                true
            );
    {% endset %}

    {{ return(sql) }}

{% endmacro %}
