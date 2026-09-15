
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_account
          
  (
    ACCOUNT_ID VARCHAR(50) not null,
    CUSTOMER_ID VARCHAR(50),
    ACCOUNT_TYPE VARCHAR(30),
    ACCOUNT_STATUS VARCHAR(30),
    CURRENT_BALANCE NUMBER(18,2),
    AVAILABLE_BALANCE NUMBER(18,2),
    OPEN_DATE DATE,
    ACCOUNT_AGE_DAYS NUMBER(38,0),
    ACCOUNT_RISK_RATING VARCHAR(20),
    CREATED_LOAD_ID NUMBER(38,0),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10),
    UPDATED_DATE_TIME TIMESTAMP_NTZ,
    UPDATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select ACCOUNT_ID, CUSTOMER_ID, ACCOUNT_TYPE, ACCOUNT_STATUS, CURRENT_BALANCE, AVAILABLE_BALANCE, OPEN_DATE, ACCOUNT_AGE_DAYS, ACCOUNT_RISK_RATING, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT, UPDATED_DATE_TIME, UPDATED_LOAD_ID
    from (
        

with source as (
    select
        cast(ACCOUNT_ID as VARCHAR(50)) as ACCOUNT_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(ACCOUNT_TYPE as VARCHAR(30)) as ACCOUNT_TYPE,
        cast(ACCOUNT_STATUS as VARCHAR(30)) as ACCOUNT_STATUS,
        cast(CURRENT_BALANCE as NUMBER(18,2)) as CURRENT_BALANCE,
        cast(AVAILABLE_BALANCE as NUMBER(18,2)) as AVAILABLE_BALANCE,
        cast(OPEN_DATE as DATE) as OPEN_DATE,
        DATEDIFF(DAY, cast(OPEN_DATE as DATE), CURRENT_DATE) as ACCOUNT_AGE_DAYS,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_account
),

enriched as (
    select
        ACCOUNT_ID,
        CUSTOMER_ID,
        ACCOUNT_TYPE,
        ACCOUNT_STATUS,
        CURRENT_BALANCE,
        AVAILABLE_BALANCE,
        OPEN_DATE,
        ACCOUNT_AGE_DAYS,
        CASE
            WHEN ACCOUNT_AGE_DAYS < 30 THEN 'HIGH'
            WHEN CURRENT_BALANCE > 1000000 THEN 'MEDIUM'
            ELSE 'LOW'
        END as ACCOUNT_RISK_RATING,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from source
),

hashed as (
    select
        *,
        md5(
            coalesce(ACCOUNT_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(ACCOUNT_TYPE, '^') || '|' ||
            coalesce(ACCOUNT_STATUS, '^') || '|' ||
            coalesce(cast(CURRENT_BALANCE as VARCHAR), '^') || '|' ||
            coalesce(cast(AVAILABLE_BALANCE as VARCHAR), '^') || '|' ||
            coalesce(cast(OPEN_DATE as VARCHAR), '^') || '|' ||
            coalesce(ACCOUNT_RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from enriched
)



    select * from hashed


    ) as model_subq
        );
      
  