
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        LOGIN_ID,
    CUSTOMER_ID,
    DEVICE_ID,
    LOGIN_TIME,
    LOGIN_STATUS,
    IP_ADDRESS,
    COUNTRY,
    STATE,
    CITY,
    SOURCE_FILE_NAME,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.login_activity
