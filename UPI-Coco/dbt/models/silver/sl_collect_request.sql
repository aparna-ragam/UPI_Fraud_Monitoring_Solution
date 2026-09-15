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
                 SELECT COLLECT_REQUEST_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY COLLECT_REQUEST_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.COLLECT_REQUEST_ID = dup.COLLECT_REQUEST_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
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
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
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
