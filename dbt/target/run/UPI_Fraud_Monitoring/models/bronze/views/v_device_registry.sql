
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_device_registry
  
  
  
  
  as (
    
        
        with cleansed as (
            select distinct
                trim(DEVICE_ID) as DEVICE_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    cast(IMEI_NUMBER as number(38,10)) as IMEI_NUMBER,
    cast(IMSI_NUMBER as number(38,10)) as IMSI_NUMBER,
    cast(SIM_NUMBER as number(38,10)) as SIM_NUMBER,
    trim(DEVICE_MAKE) as DEVICE_MAKE,
    trim(DEVICE_MODEL) as DEVICE_MODEL,
    trim(DEVICE_OS) as DEVICE_OS,
    DEVICE_REGISTRATION_DATE,
    cast(OS_VERSION as number(38,10)) as OS_VERSION,
    cast(APP_VERSION as number(38,10)) as APP_VERSION,
    trim(DEVICE_FINGERPRINT) as DEVICE_FINGERPRINT,
    TRUSTED_FLAG,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,10)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(cast(IMEI_NUMBER as string), '^') || '|' || coalesce(cast(IMSI_NUMBER as string), '^') || '|' || coalesce(cast(SIM_NUMBER as string), '^') || '|' || coalesce(trim(DEVICE_MAKE), '^') || '|' || coalesce(trim(DEVICE_MODEL), '^') || '|' || coalesce(trim(DEVICE_OS), '^') || '|' || coalesce(DEVICE_REGISTRATION_DATE::string, '^') || '|' || coalesce(cast(OS_VERSION as string), '^') || '|' || coalesce(cast(APP_VERSION as string), '^') || '|' || coalesce(trim(DEVICE_FINGERPRINT), '^') || '|' || coalesce(TRUSTED_FLAG::string, '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_device_registry
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    
  );

