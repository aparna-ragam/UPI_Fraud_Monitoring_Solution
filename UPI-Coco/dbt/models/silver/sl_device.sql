{{
    config(
        materialized='incremental',
        unique_key='DEVICE_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.DEVICE_ID IN (
                   SELECT s.DEVICE_ID FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.DEVICE_ID HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME) FROM {{ this }} s2
                   WHERE s2.DEVICE_ID = t.DEVICE_ID AND s2.IS_CURRENT = 'Y'
               )"
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
        CREATED_LOAD_ID,
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
        DEVICE_ID,
        CUSTOMER_ID,
        DEVICE_FINGERPRINT,
        DEVICE_OS,
        TRUSTED_FLAG,
        DEVICE_AGE_DAYS,
        DEVICE_RISK_SCORE,
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
        CREATED_DATE_TIME
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
