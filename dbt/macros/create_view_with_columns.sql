-- macros/select_source_columns.sql
{% macro select_source_columns(source_schema, source_table) %}
    {% set relation = source(source_schema, source_table) %}
    {% set columns = adapter.get_columns_in_relation(relation) %}

    {% set column_list = [] %}
    {% for col in columns %}
        {% do column_list.append(col.name) %}
    {% endfor %}

    select
        {{ column_list | join(',\n    ') }}
    from {{ relation }}
{% endmacro %}
