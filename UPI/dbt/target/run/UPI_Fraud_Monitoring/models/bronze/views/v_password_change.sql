
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_password_change
  
  
  
  
  as (
    
        
        with cleansed as (
            select distinct
                trim(PASSWORD_CHANGE_ID) as PASSWORD_CHANGE_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    CHANGE_TIME,
    trim(CHANGE_CHANNEL) as CHANGE_CHANNEL,
    trim(DEVICE_ID) as DEVICE_ID,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(PASSWORD_CHANGE_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(CHANGE_TIME::string, '^') || '|' || coalesce(trim(CHANGE_CHANNEL), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_password_change
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    
  );

