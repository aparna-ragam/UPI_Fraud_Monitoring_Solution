
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_password_change
          
  (
    PASSWORD_CHANGE_ID VARCHAR(100) not null,
    CUSTOMER_ID VARCHAR(50),
    CHANGE_TIME TIMESTAMP_NTZ,
    CHANGE_CHANNEL VARCHAR(50),
    DEVICE_ID VARCHAR(100),
    CHANGE_HOUR NUMBER(38,0),
    CHANGE_DAY_OF_WEEK VARCHAR(20),
    DEVICE_RISK_SCORE NUMBER(38,0),
    PASSWORD_CHANGE_RISK VARCHAR(20),
    CREATED_LOAD_ID VARCHAR(16777216),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10)
    
    )

          
        
         as
        (
    select PASSWORD_CHANGE_ID, CUSTOMER_ID, CHANGE_TIME, CHANGE_CHANNEL, DEVICE_ID, CHANGE_HOUR, CHANGE_DAY_OF_WEEK, DEVICE_RISK_SCORE, PASSWORD_CHANGE_RISK, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT
    from (
        

with source as (
    select
        cast(v.PASSWORD_CHANGE_ID as VARCHAR(100)) as PASSWORD_CHANGE_ID,
        cast(v.CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(v.CHANGE_TIME as TIMESTAMP) as CHANGE_TIME,
        cast(v.CHANGE_CHANNEL as VARCHAR(50)) as CHANGE_CHANNEL,
        cast(v.DEVICE_ID as VARCHAR(100)) as DEVICE_ID,
        extract(hour from cast(v.CHANGE_TIME as TIMESTAMP)) as CHANGE_HOUR,
        dayname(cast(v.CHANGE_TIME as TIMESTAMP)) as CHANGE_DAY_OF_WEEK,
        d.DEVICE_RISK_SCORE as DEVICE_RISK_SCORE,
        CASE
            WHEN d.DEVICE_RISK_SCORE >= 80 THEN 'HIGH'
            WHEN extract(hour from cast(v.CHANGE_TIME as TIMESTAMP)) between 0 and 4 THEN 'MEDIUM'
            ELSE 'LOW'
        END as PASSWORD_CHANGE_RISK,
        v.CREATED_LOAD_ID,
        v.CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_password_change v
    left join UPI_FRAUD_MONITORING.TRANSFORM.sl_device d
        on v.DEVICE_ID = d.DEVICE_ID and d.IS_CURRENT = 'Y'
),

hashed as (
    select
        *,
        md5(
            coalesce(PASSWORD_CHANGE_ID, '^') || '|' ||
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(cast(CHANGE_TIME as VARCHAR), '^') || '|' ||
            coalesce(CHANGE_CHANNEL, '^') || '|' ||
            coalesce(DEVICE_ID, '^') || '|' ||
            coalesce(cast(DEVICE_RISK_SCORE as VARCHAR), '^') || '|' ||
            coalesce(PASSWORD_CHANGE_RISK, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  