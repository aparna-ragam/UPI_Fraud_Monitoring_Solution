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
                 SELECT TRANSACTION_ID, MAX(CREATED_LOAD_ID) as LATEST_LOAD_ID
                 FROM {{ this }}
                 WHERE IS_CURRENT = 'Y'
                 GROUP BY TRANSACTION_ID
                 HAVING COUNT(*) > 1
             ) dup
             WHERE t.TRANSACTION_ID = dup.TRANSACTION_ID
               AND t.IS_CURRENT = 'Y'
               AND t.CREATED_LOAD_ID < dup.LATEST_LOAD_ID"
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
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
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
