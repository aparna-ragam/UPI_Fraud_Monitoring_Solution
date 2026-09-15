{{
    config(
        materialized='incremental',
        unique_key='TRANSACTION_ID',
        incremental_strategy='merge',
        post_hook=[
            "UPDATE {{ this }} t
             SET t.IS_CURRENT = 'N'
             WHERE t.IS_CURRENT = 'Y'
               AND t.TRANSACTION_ID IN (
                   SELECT s.TRANSACTION_ID
                   FROM {{ this }} s
                   WHERE s.IS_CURRENT = 'Y'
                   GROUP BY s.TRANSACTION_ID
                   HAVING COUNT(*) > 1
               )
               AND t.CREATED_DATE_TIME < (
                   SELECT MAX(s2.CREATED_DATE_TIME)
                   FROM {{ this }} s2
                   WHERE s2.TRANSACTION_ID = t.TRANSACTION_ID
                     AND s2.IS_CURRENT = 'Y'
               )"
        ]
    )
}}

with source as (
    select
        cast(TRANSACTION_ID as VARCHAR(100)) as TRANSACTION_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(ACCOUNT_ID as VARCHAR(50)) as ACCOUNT_ID,
        cast(BENEFICIARY_ID as VARCHAR(100)) as BENEFICIARY_ID,
        cast(MERCHANT_ID as VARCHAR(100)) as MERCHANT_ID,
        cast(DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        cast(TXN_DATETIME as TIMESTAMP) as TXN_DATETIME,
        cast(TXN_AMOUNT as NUMBER(18,2)) as TXN_AMOUNT,
        cast(TXN_TYPE as VARCHAR(50)) as TXN_TYPE,
        cast(TXN_STATUS as VARCHAR(30)) as TXN_STATUS,
        cast(CHANNEL as VARCHAR(50)) as CHANNEL,
        cast(NULL as VARCHAR(100)) as COUNTRY,
        cast(NULL as VARCHAR(100)) as STATE,
        CASE
            WHEN cast(TXN_AMOUNT as NUMBER(18,2)) >= 100000 THEN 'HIGH_VALUE_TXN'
            WHEN DEVICE_ID IN (SELECT DEVICE_ID FROM {{ ref('v_device_registry') }} WHERE TRUSTED_FLAG = 'N') THEN 'UNTRUSTED_DEVICE'
            WHEN BENEFICIARY_ID IN (SELECT BENEFICIARY_ID FROM {{ ref('v_beneficiary') }} WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_BENEFICIARY'
            WHEN MERCHANT_ID IN (SELECT MERCHANT_ID FROM {{ ref('v_merchant') }} WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_MERCHANT'
            WHEN CUSTOMER_ID IN (SELECT CUSTOMER_ID FROM {{ ref('v_raw_customer') }} WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_CUSTOMER'
            WHEN TXN_STATUS = 'FAILED' THEN 'FAILED_TRANSACTION'
            ELSE 'NORMAL'
        END as TXN_RISK_REASON,
        cast(NULL as VARCHAR(50)) as TXN_FRAUD_ID,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from {{ ref('v_transaction') }}
),

hashed as (
    select
        *,
        md5(
            coalesce(TRANSACTION_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(ACCOUNT_ID, '^') || '|' ||
            coalesce(BENEFICIARY_ID, '^') || '|' ||
            coalesce(MERCHANT_ID, '^') || '|' ||
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(cast(TXN_DATETIME as VARCHAR), '^') || '|' ||
            coalesce(cast(TXN_AMOUNT as VARCHAR), '^') || '|' ||
            coalesce(TXN_TYPE, '^') || '|' ||
            coalesce(TXN_STATUS, '^') || '|' ||
            coalesce(CHANNEL, '^') || '|' ||
            coalesce(TXN_RISK_REASON, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)

{% if is_incremental() %}

    select h.*
    from hashed h
    left join {{ this }} t
        on h.TRANSACTION_ID = t.TRANSACTION_ID
        and t.IS_CURRENT = 'Y'
    where t.TRANSACTION_ID is null
       or h.HASH_DIFF != t.HASH_DIFF

{% else %}

    select * from hashed

{% endif %}
