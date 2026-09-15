{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        on_schema_change='append_new_columns',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N',
                 t.UPDATED_DATE_TIME = CURRENT_TIMESTAMP(),
                 t.UPDATED_LOAD_ID = dup.LATEST_LOAD_ID
             FROM (
                 SELECT WATCHLIST_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY WATCHLIST_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.WATCHLIST_ID = dup.WATCHLIST_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
        ]
    )
}}

with source as (
    select
        cast(WATCHLIST_ID as VARCHAR(100)) as WATCHLIST_ID,
        cast(ENTITY_TYPE as VARCHAR(50)) as ENTITY_TYPE,
        cast(ENTITY_ID as VARCHAR(100)) as ENTITY_ID,
        cast(ENTITY_NAME as VARCHAR(255)) as ENTITY_NAME,
        cast(RISK_LEVEL as VARCHAR(20)) as RISK_LEVEL,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_watchlist') }}
),

hashed as (
    select
        *,
        md5(
            coalesce(WATCHLIST_ID, '^') || '|' ||
            coalesce(ENTITY_TYPE, '^') || '|' ||
            coalesce(ENTITY_ID, '^') || '|' ||
            coalesce(ENTITY_NAME, '^') || '|' ||
            coalesce(RISK_LEVEL, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.WATCHLIST_ID = t.WATCHLIST_ID and t.IS_CURRENT = 'Y'
    where t.WATCHLIST_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
