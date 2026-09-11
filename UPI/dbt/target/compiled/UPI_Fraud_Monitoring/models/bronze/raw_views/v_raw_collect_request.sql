
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        COLLECT_REQUEST_ID,
    CUSTOMER_ID,
    REQUEST_AMOUNT,
    REQUEST_TIME,
    REQUEST_STATUS,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.collect_request
