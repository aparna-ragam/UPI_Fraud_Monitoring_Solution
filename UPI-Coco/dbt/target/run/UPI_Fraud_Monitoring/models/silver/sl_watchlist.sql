
  
    

        create or replace transient table UPI_FRAUD_MONITORING.TRANSFORM.sl_watchlist
          
  (
    WATCHLIST_ID VARCHAR(100) not null,
    ENTITY_TYPE VARCHAR(50),
    ENTITY_ID VARCHAR(100),
    ENTITY_NAME VARCHAR(255),
    RISK_LEVEL VARCHAR(20),
    CREATED_LOAD_ID NUMBER(38,0),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    HASH_DIFF VARCHAR(2000),
    IS_CURRENT VARCHAR(10),
    UPDATED_DATE_TIME TIMESTAMP_NTZ,
    UPDATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select WATCHLIST_ID, ENTITY_TYPE, ENTITY_ID, ENTITY_NAME, RISK_LEVEL, CREATED_LOAD_ID, CREATED_DATE_TIME, HASH_DIFF, IS_CURRENT, UPDATED_DATE_TIME, UPDATED_LOAD_ID
    from (
        

with source as (
    select
        cast(WATCHLIST_ID as VARCHAR(100)) as WATCHLIST_ID,
        cast(ENTITY_TYPE as VARCHAR(50)) as ENTITY_TYPE,
        cast(ENTITY_ID as VARCHAR(100)) as ENTITY_ID,
        cast(ENTITY_NAME as VARCHAR(255)) as ENTITY_NAME,
        cast(RISK_LEVEL as VARCHAR(20)) as RISK_LEVEL,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
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
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)



    select * from hashed


    ) as model_subq
        );
      
  