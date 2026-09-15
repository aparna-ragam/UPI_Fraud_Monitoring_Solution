

    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        DEVICE_ID,
    CUSTOMER_ID,
    IMEI_NUMBER,
    IMSI_NUMBER,
    SIM_NUMBER,
    DEVICE_MAKE,
    DEVICE_MODEL,
    DEVICE_OS,
    DEVICE_REGISTRATION_DATE,
    OS_VERSION,
    APP_VERSION,
    DEVICE_FINGERPRINT,
    TRUSTED_FLAG,
    SOURCE_FILE_NAME,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.device_registry
