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
                 SELECT DEVICE_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY DEVICE_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.DEVICE_ID = dup.DEVICE_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
        ]
    )
}}

with source as (
    select
        cast(DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(DEVICE_FINGERPRINT as VARCHAR(500)) as DEVICE_FINGERPRINT,
        cast(DEVICE_OS as VARCHAR(50)) as DEVICE_OS,
        cast(TRUSTED_FLAG as VARCHAR(1)) as TRUSTED_FLAG,
        DATEDIFF(DAY, cast(DEVICE_REGISTRATION_DATE as DATE), CURRENT_DATE) as DEVICE_AGE_DAYS,
        OS_VERSION,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_device_registry') }}
),

enriched as (
    select
        DEVICE_ID,
        CUSTOMER_ID,
        DEVICE_FINGERPRINT,
        DEVICE_OS,
        TRUSTED_FLAG,
        DEVICE_AGE_DAYS,
        (CASE WHEN TRUSTED_FLAG = 'N' THEN 40 ELSE 0 END)
        + (CASE WHEN DEVICE_AGE_DAYS < 30 THEN 30 ELSE 0 END)
        + (CASE WHEN OS_VERSION < 'Android 10' THEN 20 ELSE 0 END) as DEVICE_RISK_SCORE,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from source
),

hashed as (
    select
        DEVICE_ID, CUSTOMER_ID, DEVICE_FINGERPRINT, DEVICE_OS, TRUSTED_FLAG,
        DEVICE_AGE_DAYS, DEVICE_RISK_SCORE,
        md5(
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(DEVICE_FINGERPRINT, '^') || '|' ||
            coalesce(DEVICE_OS, '^') || '|' ||
            coalesce(TRUSTED_FLAG, '^') || '|' ||
            coalesce(cast(DEVICE_RISK_SCORE as VARCHAR), '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from enriched
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.DEVICE_ID = t.DEVICE_ID and t.IS_CURRENT = 'Y'
    where t.DEVICE_ID is null or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
