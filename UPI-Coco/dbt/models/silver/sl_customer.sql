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
                 SELECT CUSTOMER_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY CUSTOMER_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.CUSTOMER_ID = dup.CUSTOMER_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
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
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
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
