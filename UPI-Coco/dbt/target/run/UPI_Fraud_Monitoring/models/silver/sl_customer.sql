
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_customer
          
  (
    CUSTOMER_ID VARCHAR(50) not null,
    CUSTOMER_NAME VARCHAR(255),
    CUSTOMER_SEGMENT VARCHAR(50),
    KYC_STATUS VARCHAR(30),
    RISK_RATING VARCHAR(20),
    CUSTOMER_STATUS VARCHAR(30),
    CUSTOMER_SINCE DATE,
    CUSTOMER_TYPE VARCHAR(50),
    CREATED_LOAD_ID VARCHAR(16777216),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10)
    
    )

          
        
         as
        (
    select CUSTOMER_ID, CUSTOMER_NAME, CUSTOMER_SEGMENT, KYC_STATUS, RISK_RATING, CUSTOMER_STATUS, CUSTOMER_SINCE, CUSTOMER_TYPE, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT
    from (
        

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
    from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_customer
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



    select * from hashed


    ) as model_subq
        );
      
  