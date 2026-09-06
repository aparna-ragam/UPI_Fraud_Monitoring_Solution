
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_merchant
  
  
  
  
  as (
    
        
        with cleansed as (
            select distinct
                trim(MERCHANT_ID) as MERCHANT_ID,
    trim(MERCHANT_NAME) as MERCHANT_NAME,
    trim(MERCHANT_CATEGORY) as MERCHANT_CATEGORY,
    trim(MERCHANT_STATUS) as MERCHANT_STATUS,
    trim(RISK_RATING) as RISK_RATING,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,10)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(MERCHANT_ID), '^') || '|' || coalesce(trim(MERCHANT_NAME), '^') || '|' || coalesce(trim(MERCHANT_CATEGORY), '^') || '|' || coalesce(trim(MERCHANT_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_merchant
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    
  );

