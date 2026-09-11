{% macro generate_contract(model_name) %}
    {% set relation = ref(model_name) %}
    {% set sql %}
        select column_name, data_type
        from {{ relation.database }}.information_schema.columns
        where table_name = '{{ relation.identifier }}'
          and table_schema = '{{ relation.schema }}'
    {% endset %}

    {% set results = run_query(sql) %}

    {% if execute %}
        {% for row in results.rows %}
            {{ log("- name: " ~ row[0]|lower ~ "\n  data_type: " ~ row[1]|lower, info=True) }}
        {% endfor %}
    {% else %}
        {{ log("Macro skipped because not executing", info=True) }}
    {% endif %}
{% endmacro %}
