-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) %}
    {# 
      If a custom schema is defined in dbt_project.yml (folder-level),
      use it directly. Otherwise, fall back to the target.schema from profiles.yml.
    #}
    {% if custom_schema_name is not none %}
        {{ custom_schema_name }}
    {% else %}
        {{ target.schema }}
    {% endif %}
{% endmacro %}
