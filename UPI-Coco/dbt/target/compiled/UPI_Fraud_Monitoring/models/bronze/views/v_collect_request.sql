

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(COLLECT_REQUEST_ID) as COLLECT_REQUEST_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(REQUEST_AMOUNT) as REQUEST_AMOUNT,
            trim(REQUEST_TIME) as REQUEST_TIME,
            trim(REQUEST_STATUS) as REQUEST_STATUS,
            trim(CREATED_LOAD_ID) as CREATED_LOAD_ID,
            CREATED_DATE_TIME,
            md5(coalesce(trim(COLLECT_REQUEST_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(REQUEST_AMOUNT), '^') || '|' || coalesce(trim(REQUEST_TIME), '^') || '|' || coalesce(trim(REQUEST_STATUS), '^') || '|' || coalesce(trim(CREATED_LOAD_ID), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_collect_request
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

