{{
    config(
        materialized='incremental',
        unique_key='COLLECT_REQUEST_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.COLLECT_REQUEST_ID IN (
                   SELECT s.COLLECT_REQUEST_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.COLLECT_REQUEST_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.COLLECT_REQUEST_ID = t.COLLECT_REQUEST_ID AND s2.IS_CURRENT = 'Y'
               )"
        ]
    )
}}

with source as (
    select
        cast(COLLECT_REQUEST_ID as VARCHAR(100)) as COLLECT_REQUEST_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(REQUEST_AMOUNT as NUMBER(18,2)) as REQUEST_AMOUNT,
        cast(REQUEST_TIME as TIMESTAMP) as REQUEST_TIME,
        cast(REQUEST_STATUS as VARCHAR(30)) as REQUEST_STATUS,
        extract(hour from cast(REQUEST_TIME as TIMESTAMP)) as REQUEST_HOUR,
        dayname(cast(REQUEST_TIME as TIMESTAMP)) as REQUEST_DAY_OF_WEEK,
        CASE
            WHEN cast(REQUEST_AMOUNT as NUMBER(18,2)) >= 100000 THEN 'HIGH'
            WHEN REQUEST_STATUS = 'FAILED' THEN 'MEDIUM'
            ELSE 'LOW'
        END as REQUEST_RISK_RATING,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_collect_request') }}
),

hashed as (
    select
        *,
        md5(
            coalesce(COLLECT_REQUEST_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(cast(REQUEST_AMOUNT as VARCHAR), '^') || '|' ||
            coalesce(cast(REQUEST_TIME as VARCHAR), '^') || '|' ||
            coalesce(REQUEST_STATUS, '^') || '|' ||
            coalesce(REQUEST_RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.COLLECT_REQUEST_ID = t.COLLECT_REQUEST_ID and t.IS_CURRENT = 'Y'
    where t.COLLECT_REQUEST_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
