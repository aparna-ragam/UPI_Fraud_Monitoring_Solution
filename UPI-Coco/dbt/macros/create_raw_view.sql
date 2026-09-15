{% macro create_raw_view(source_name, table_name) %}

    {% set relation = source(source_name, table_name) %}
    {% set columns = adapter.get_columns_in_relation(relation) %}

    select
        {% for col in columns %}
        {{ col.name }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from {{ relation }}

{% endmacro %}
