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
                 SELECT MERCHANT_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY MERCHANT_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.MERCHANT_ID = dup.MERCHANT_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
        ]
    )
}}

with source as (
    select
        cast(MERCHANT_ID as VARCHAR(100)) as MERCHANT_ID,
        cast(MERCHANT_NAME as VARCHAR(255)) as MERCHANT_NAME,
        cast(MERCHANT_CATEGORY as VARCHAR(100)) as MERCHANT_CATEGORY,
        cast(MERCHANT_STATUS as VARCHAR(50)) as MERCHANT_STATUS,
        CASE
            WHEN MERCHANT_CATEGORY = 'Grocery' THEN '5411'
            WHEN MERCHANT_CATEGORY = 'Fuel' THEN '5541'
            WHEN MERCHANT_CATEGORY = 'Retail' THEN '6000'
            ELSE '9999'
        END as MCC_CODE,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_merchant') }}
),

enriched as (
    select
        MERCHANT_ID, MERCHANT_NAME, MERCHANT_CATEGORY,
        cast(MCC_CODE as VARCHAR(20)) as MCC_CODE,
        MERCHANT_STATUS,
        CASE
            WHEN MCC_CODE IN ('5411', '5541', '5812') THEN 'LOW'
            WHEN MCC_CODE IN ('6000') THEN 'MEDIUM'
            ELSE 'HIGH_RISK'
        END as RISK_RATING,
        CREATED_LOAD_ID, CREATED_DATE_TIME
    from source
),

hashed as (
    select
        *,
        md5(
            coalesce(MERCHANT_ID, '^') || '|' ||
            coalesce(MERCHANT_NAME, '^') || '|' ||
            coalesce(MERCHANT_CATEGORY, '^') || '|' ||
            coalesce(MCC_CODE, '^') || '|' ||
            coalesce(MERCHANT_STATUS, '^') || '|' ||
            coalesce(RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from enriched
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.MERCHANT_ID = t.MERCHANT_ID and t.IS_CURRENT = 'Y'
    where t.MERCHANT_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
