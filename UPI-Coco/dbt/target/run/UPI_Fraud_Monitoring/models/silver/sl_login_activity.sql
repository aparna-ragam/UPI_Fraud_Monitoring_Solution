
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_login_activity
          
  (
    LOGIN_ID VARCHAR(100) not null,
    CUSTOMER_ID VARCHAR(50),
    DEVICE_ID VARCHAR(100),
    LOGIN_TIME TIMESTAMP_NTZ,
    LOGIN_STATUS VARCHAR(30),
    COUNTRY VARCHAR(100),
    STATE VARCHAR(100),
    CITY VARCHAR(100),
    IP_ADDRESS VARCHAR(100),
    CREATED_LOAD_ID VARCHAR(16777216),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10)
    
    )

          
        
         as
        (
    select LOGIN_ID, CUSTOMER_ID, DEVICE_ID, LOGIN_TIME, LOGIN_STATUS, COUNTRY, STATE, CITY, IP_ADDRESS, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT
    from (
        

with source as (
    select
        cast(LOGIN_ID as VARCHAR(100)) as LOGIN_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        cast(LOGIN_TIME as TIMESTAMP) as LOGIN_TIME,
        cast(LOGIN_STATUS as VARCHAR(30)) as LOGIN_STATUS,
        cast(COUNTRY as VARCHAR(100)) as COUNTRY,
        cast(STATE as VARCHAR(100)) as STATE,
        cast(CITY as VARCHAR(100)) as CITY,
        cast(IP_ADDRESS as VARCHAR(100)) as IP_ADDRESS,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_login_activity
),

hashed as (
    select
        *,
        md5(
            coalesce(LOGIN_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(cast(LOGIN_TIME as VARCHAR), '^') || '|' ||
            coalesce(LOGIN_STATUS, '^') || '|' ||
            coalesce(COUNTRY, '^') || '|' ||
            coalesce(STATE, '^') || '|' ||
            coalesce(CITY, '^') || '|' ||
            coalesce(IP_ADDRESS, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  