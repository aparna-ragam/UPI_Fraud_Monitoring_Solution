
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_collect_request
          
  (
    COLLECT_REQUEST_ID VARCHAR(100) not null,
    CUSTOMER_ID VARCHAR(50),
    REQUEST_AMOUNT NUMBER(18,2),
    REQUEST_TIME TIMESTAMP_NTZ,
    REQUEST_STATUS VARCHAR(30),
    REQUEST_HOUR NUMBER(38,0),
    REQUEST_DAY_OF_WEEK VARCHAR(20),
    REQUEST_RISK_RATING VARCHAR(20),
    CREATED_LOAD_ID NUMBER(38,0),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10),
    UPDATED_DATE_TIME TIMESTAMP_NTZ,
    UPDATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select COLLECT_REQUEST_ID, CUSTOMER_ID, REQUEST_AMOUNT, REQUEST_TIME, REQUEST_STATUS, REQUEST_HOUR, REQUEST_DAY_OF_WEEK, REQUEST_RISK_RATING, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT, UPDATED_DATE_TIME, UPDATED_LOAD_ID
    from (
        

with source as (
    select
        cast(COLLECT_REQUEST_ID as VARCHAR(100)) as COLLECT_REQUEST_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(REQUEST_AMOUNT as NUMBER(18,2)) as REQUEST_AMOUNT,
        cast(REQUEST_TIME as TIMESTAMP) as REQUEST_TIME,
        cast(REQUEST_STATUS as VARCHAR(30)) as REQUEST_STATUS,
        extract(hour from cast(REQUEST_TIME as TIMESTAMP)) as REQUEST_HOUR,
        dayname(cast(REQUEST_TIME as TIMESTAMP)) as REQUEST_DAY_OF_WEEK,
        CASE
            WHEN cast(REQUEST_AMOUNT as NUMBER(18,2)) >= 100000 THEN 'HIGH'
            WHEN REQUEST_STATUS = 'FAILED' THEN 'MEDIUM'
            ELSE 'LOW'
        END as REQUEST_RISK_RATING,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_collect_request
),

hashed as (
    select
        *,
        md5(
            coalesce(COLLECT_REQUEST_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(cast(REQUEST_AMOUNT as VARCHAR), '^') || '|' ||
            coalesce(cast(REQUEST_TIME as VARCHAR), '^') || '|' ||
            coalesce(REQUEST_STATUS, '^') || '|' ||
            coalesce(REQUEST_RISK_RATING, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  