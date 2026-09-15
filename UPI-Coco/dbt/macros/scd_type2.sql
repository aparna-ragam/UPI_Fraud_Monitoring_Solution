{% macro scd_type2(source_ref, unique_key, columns, hash_columns, target_table) %}

{#
  SCD Type 2 Macro
  - source_ref:    dbt ref name of the source view (e.g. 'v_transaction')
  - unique_key:    business key column (e.g. 'TRANSACTION_ID')
  - columns:       list of column select expressions from source
  - hash_columns:  list of columns to include in hash_diff for change detection
  - target_table:  the current model's this() reference
#}

{% set source = ref(source_ref) %}

{% if is_incremental() %}

    -- Step 1: incoming records with hash
    with incoming as (
        select
            {{ columns | join(',\n            ') }},
            md5({{ hash_columns | join(" || '|' || ") }}) as HASH_DIFF,
            'Y' as IS_CURRENT,
            CREATED_LOAD_ID,
            CREATED_DATE_TIME
        from {{ source }}
    ),

    -- Step 2: detect changes against current records in target
    changes as (
        select i.*
        from incoming i
        left join {{ target_table }} t
            on i.{{ unique_key }} = t.{{ unique_key }}
            and t.IS_CURRENT = 'Y'
        where t.{{ unique_key }} is null
           or i.HASH_DIFF != t.HASH_DIFF
    )

    -- Step 3: expire old current records (handled via post-hook)
    -- Step 4: insert new/changed records
    select * from changes

{% else %}

    -- Full refresh: load all records as current
    select
        {{ columns | join(',\n        ') }},
        md5({{ hash_columns | join(" || '|' || ") }}) as HASH_DIFF,
        'Y' as IS_CURRENT,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ source }}

{% endif %}

{% endmacro %}
