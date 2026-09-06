

    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        ACCOUNT_ID,
    CUSTOMER_ID,
    ACCOUNT_NUMBER,
    ACCOUNT_TYPE,
    BRANCH_CODE,
    IFSC_CODE,
    OPEN_DATE,
    ACCOUNT_STATUS,
    CURRENT_BALANCE,
    AVAILABLE_BALANCE,
    SOURCE_FILE_NAME,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.account_master
