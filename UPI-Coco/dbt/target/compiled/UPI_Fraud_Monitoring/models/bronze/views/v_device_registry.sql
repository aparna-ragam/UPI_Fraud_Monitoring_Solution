

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(DEVICE_ID) as DEVICE_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(IMEI_NUMBER) as IMEI_NUMBER,
            trim(IMSI_NUMBER) as IMSI_NUMBER,
            trim(SIM_NUMBER) as SIM_NUMBER,
            trim(DEVICE_MAKE) as DEVICE_MAKE,
            trim(DEVICE_MODEL) as DEVICE_MODEL,
            trim(DEVICE_OS) as DEVICE_OS,
            trim(DEVICE_REGISTRATION_DATE) as DEVICE_REGISTRATION_DATE,
            trim(OS_VERSION) as OS_VERSION,
            trim(APP_VERSION) as APP_VERSION,
            trim(DEVICE_FINGERPRINT) as DEVICE_FINGERPRINT,
            trim(TRUSTED_FLAG) as TRUSTED_FLAG,
            CREATED_DATE_TIME,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(IMEI_NUMBER), '^') || '|' || coalesce(trim(IMSI_NUMBER), '^') || '|' || coalesce(trim(SIM_NUMBER), '^') || '|' || coalesce(trim(DEVICE_MAKE), '^') || '|' || coalesce(trim(DEVICE_MODEL), '^') || '|' || coalesce(trim(DEVICE_OS), '^') || '|' || coalesce(trim(DEVICE_REGISTRATION_DATE), '^') || '|' || coalesce(trim(OS_VERSION), '^') || '|' || coalesce(trim(APP_VERSION), '^') || '|' || coalesce(trim(DEVICE_FINGERPRINT), '^') || '|' || coalesce(trim(TRUSTED_FLAG), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_device_registry
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

