
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_merchant
          
  (
    MERCHANT_ID VARCHAR(100) not null,
    MERCHANT_NAME VARCHAR(255),
    MERCHANT_CATEGORY VARCHAR(100),
    MCC_CODE VARCHAR(20),
    MERCHANT_STATUS VARCHAR(50),
    RISK_RATING VARCHAR(20),
    CREATED_LOAD_ID NUMBER(38,0),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10),
    UPDATED_DATE_TIME TIMESTAMP_NTZ,
    UPDATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select MERCHANT_ID, MERCHANT_NAME, MERCHANT_CATEGORY, MCC_CODE, MERCHANT_STATUS, RISK_RATING, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT, UPDATED_DATE_TIME, UPDATED_LOAD_ID
    from (
        

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
    from UPI_FRAUD_MONITORING.TRANSFORM.v_merchant
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



    select * from hashed


    ) as model_subq
        );
      
  