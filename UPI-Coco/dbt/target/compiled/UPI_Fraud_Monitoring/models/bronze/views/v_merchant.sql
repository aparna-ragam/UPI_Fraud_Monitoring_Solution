

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(MERCHANT_ID) as MERCHANT_ID,
            trim(MERCHANT_NAME) as MERCHANT_NAME,
            trim(MERCHANT_CATEGORY) as MERCHANT_CATEGORY,
            trim(MERCHANT_STATUS) as MERCHANT_STATUS,
            trim(RISK_RATING) as RISK_RATING,
            CREATED_DATE_TIME,
            trim(TESTING) as TESTING,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(MERCHANT_ID), '^') || '|' || coalesce(trim(MERCHANT_NAME), '^') || '|' || coalesce(trim(MERCHANT_CATEGORY), '^') || '|' || coalesce(trim(MERCHANT_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(trim(TESTING), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_merchant
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

