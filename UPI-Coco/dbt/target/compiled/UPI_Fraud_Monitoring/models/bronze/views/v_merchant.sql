

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(MERCHANT_ID) as MERCHANT_ID,
            trim(MERCHANT_NAME) as MERCHANT_NAME,
            trim(MERCHANT_CATEGORY) as MERCHANT_CATEGORY,
            trim(MERCHANT_STATUS) as MERCHANT_STATUS,
            trim(RISK_RATING) as RISK_RATING,
            trim(CREATED_LOAD_ID) as CREATED_LOAD_ID,
            CREATED_DATE_TIME,
            trim(TESTING) as TESTING,
            md5(coalesce(trim(MERCHANT_ID), '^') || '|' || coalesce(trim(MERCHANT_NAME), '^') || '|' || coalesce(trim(MERCHANT_CATEGORY), '^') || '|' || coalesce(trim(MERCHANT_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(trim(CREATED_LOAD_ID), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(trim(TESTING), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_merchant
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

