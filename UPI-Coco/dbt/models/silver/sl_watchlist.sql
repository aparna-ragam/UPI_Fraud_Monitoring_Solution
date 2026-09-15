{{
    config(
        materialized='incremental',
        unique_key='WATCHLIST_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.WATCHLIST_ID IN (
                   SELECT s.WATCHLIST_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.WATCHLIST_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.WATCHLIST_ID = t.WATCHLIST_ID AND s2.IS_CURRENT = 'Y'
               )"
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
        CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT
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
