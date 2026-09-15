
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_transaction
          
  (
    TRANSACTION_ID VARCHAR(100) not null,
    CUSTOMER_ID VARCHAR(50),
    ACCOUNT_ID VARCHAR(50),
    BENEFICIARY_ID VARCHAR(100),
    MERCHANT_ID VARCHAR(100),
    DEVICE_ID VARCHAR(100),
    TXN_DATETIME TIMESTAMP_NTZ,
    TXN_AMOUNT NUMBER(18,2),
    TXN_TYPE VARCHAR(50),
    TXN_STATUS VARCHAR(30),
    CHANNEL VARCHAR(50),
    COUNTRY VARCHAR(100),
    STATE VARCHAR(100),
    TXN_RISK_REASON VARCHAR(50),
    TXN_FRAUD_ID VARCHAR(50),
    CREATED_LOAD_ID NUMBER(38,0),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10),
    UPDATED_DATE_TIME TIMESTAMP_NTZ,
    UPDATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select TRANSACTION_ID, CUSTOMER_ID, ACCOUNT_ID, BENEFICIARY_ID, MERCHANT_ID, DEVICE_ID, TXN_DATETIME, TXN_AMOUNT, TXN_TYPE, TXN_STATUS, CHANNEL, COUNTRY, STATE, TXN_RISK_REASON, TXN_FRAUD_ID, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT, UPDATED_DATE_TIME, UPDATED_LOAD_ID
    from (
        

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
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  