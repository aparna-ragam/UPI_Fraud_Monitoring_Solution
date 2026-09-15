{{
    config(
        materialized='incremental',
        unique_key='CUSTOMER_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.CUSTOMER_ID IN (
                   SELECT s.CUSTOMER_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.CUSTOMER_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.CUSTOMER_ID = t.CUSTOMER_ID AND s2.IS_CURRENT = 'Y'
               )"
        ]
    )
}}

with source as (
    select
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(CUSTOMER_NAME as VARCHAR(255)) as CUSTOMER_NAME,
        cast(CUSTOMER_SEGMENT as VARCHAR(50)) as CUSTOMER_SEGMENT,
        cast(KYC_STATUS as VARCHAR(30)) as KYC_STATUS,
        cast(RISK_RATING as VARCHAR(20)) as RISK_RATING,
        cast(CUSTOMER_STATUS as VARCHAR(30)) as CUSTOMER_STATUS,
        cast(CUSTOMER_SINCE as DATE) as CUSTOMER_SINCE,
        cast(CUSTOMER_TYPE as VARCHAR(50)) as CUSTOMER_TYPE,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_raw_customer') }}
),

hashed as (
    select
        *,
        md5(
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(CUSTOMER_NAME, '^') || '|' ||
            coalesce(CUSTOMER_SEGMENT, '^') || '|' ||
            coalesce(KYC_STATUS, '^') || '|' ||
            coalesce(RISK_RATING, '^') || '|' ||
            coalesce(CUSTOMER_STATUS, '^') || '|' ||
            coalesce(cast(CUSTOMER_SINCE as VARCHAR), '^') || '|' ||
            coalesce(CUSTOMER_TYPE, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.CUSTOMER_ID = t.CUSTOMER_ID and t.IS_CURRENT = 'Y'
    where t.CUSTOMER_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
