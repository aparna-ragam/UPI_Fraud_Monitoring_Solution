{{
    config(
        materialized='incremental',
        unique_key='MERCHANT_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.MERCHANT_ID IN (
                   SELECT s.MERCHANT_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.MERCHANT_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.MERCHANT_ID = t.MERCHANT_ID AND s2.IS_CURRENT = 'Y'
               )"
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
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_merchant') }}
),

enriched as (
    select
        MERCHANT_ID,
        MERCHANT_NAME,
        MERCHANT_CATEGORY,
        cast(MCC_CODE as VARCHAR(20)) as MCC_CODE,
        MERCHANT_STATUS,
        CASE
            WHEN MCC_CODE IN ('5411', '5541', '5812') THEN 'LOW'
            WHEN MCC_CODE IN ('6000') THEN 'MEDIUM'
            ELSE 'HIGH_RISK'
        END as RISK_RATING,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
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
        'Y' as IS_CURRENT
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
