

    
    

    select
        
        COLLECT_REQUEST_ID,
        
        CUSTOMER_ID,
        
        REQUEST_AMOUNT,
        
        REQUEST_TIME,
        
        REQUEST_STATUS,
        
        CREATED_DATE_TIME,
        
        CREATED_LOAD_ID
        
    from UPI_FRAUD_MONITORING.STAGING.collect_request

