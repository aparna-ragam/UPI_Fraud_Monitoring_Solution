
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_collect_request
  
  
  
  
  as (
    
        
        with cleansed as (
            select distinct
                trim(COLLECT_REQUEST_ID) as COLLECT_REQUEST_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    cast(REQUEST_AMOUNT as number(38,0)) as REQUEST_AMOUNT,
    REQUEST_TIME,
    trim(REQUEST_STATUS) as REQUEST_STATUS,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(COLLECT_REQUEST_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(cast(REQUEST_AMOUNT as string), '^') || '|' || coalesce(REQUEST_TIME::string, '^') || '|' || coalesce(trim(REQUEST_STATUS), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_collect_request
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    
  );

