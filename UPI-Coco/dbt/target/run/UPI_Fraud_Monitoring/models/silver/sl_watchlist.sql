
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_watchlist
          
  (
    WATCHLIST_ID VARCHAR(100) not null,
    ENTITY_TYPE VARCHAR(50),
    ENTITY_ID VARCHAR(100),
    ENTITY_NAME VARCHAR(255),
    RISK_LEVEL VARCHAR(20),
    CREATED_LOAD_ID VARCHAR(16777216),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10)
    
    )

          
        
         as
        (
    select WATCHLIST_ID, ENTITY_TYPE, ENTITY_ID, ENTITY_NAME, RISK_LEVEL, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT
    from (
        

with source as (
    select
        cast(WATCHLIST_ID as VARCHAR(100)) as WATCHLIST_ID,
        cast(ENTITY_TYPE as VARCHAR(50)) as ENTITY_TYPE,
        cast(ENTITY_ID as VARCHAR(100)) as ENTITY_ID,
        cast(ENTITY_NAME as VARCHAR(255)) as ENTITY_NAME,
        cast(RISK_LEVEL as VARCHAR(20)) as RISK_LEVEL,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_watchlist
),

hashed as (
    select
        *,
        md5(
            coalesce(WATCHLIST_ID, '^') || '|' ||
            coalesce(ENTITY_TYPE, '^') || '|' ||
            coalesce(ENTITY_ID, '^') || '|' ||
            coalesce(ENTITY_NAME, '^') || '|' ||
            coalesce(RISK_LEVEL, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  