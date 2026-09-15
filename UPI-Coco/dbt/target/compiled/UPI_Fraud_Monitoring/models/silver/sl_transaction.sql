

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
            WHEN DEVICE_ID IN (SELECT DEVICE_ID FROM UPI_FRAUD_MONITORING.TRANSFORM.v_device_registry WHERE TRUSTED_FLAG = 'N') THEN 'UNTRUSTED_DEVICE'
            WHEN BENEFICIARY_ID IN (SELECT BENEFICIARY_ID FROM UPI_FRAUD_MONITORING.TRANSFORM.v_beneficiary WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_BENEFICIARY'
            WHEN MERCHANT_ID IN (SELECT MERCHANT_ID FROM UPI_FRAUD_MONITORING.TRANSFORM.v_merchant WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_MERCHANT'
            WHEN CUSTOMER_ID IN (SELECT CUSTOMER_ID FROM UPI_FRAUD_MONITORING.TRANSFORM.v_raw_customer WHERE RISK_RATING = 'HIGH') THEN 'HIGH_RISK_CUSTOMER'
            WHEN TXN_STATUS = 'FAILED' THEN 'FAILED_TRANSACTION'
            ELSE 'NORMAL'
        END as TXN_RISK_REASON,
        cast(NULL as VARCHAR(50)) as TXN_FRAUD_ID,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_transaction
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



    select * from hashed

