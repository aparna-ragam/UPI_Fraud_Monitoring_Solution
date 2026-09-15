

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(BENEFICIARY_ID) as BENEFICIARY_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(BENEFICIARY_NAME) as BENEFICIARY_NAME,
            trim(BENEFICIARY_VPA) as BENEFICIARY_VPA,
            trim(BENEFICIARY_CREATED_DATE) as BENEFICIARY_CREATED_DATE,
            trim(BANK_NAME) as BANK_NAME,
            trim(RISK_RATING) as RISK_RATING,
            trim(CREATED_LOAD_ID) as CREATED_LOAD_ID,
            CREATED_DATE_TIME,
            md5(coalesce(trim(BENEFICIARY_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(BENEFICIARY_NAME), '^') || '|' || coalesce(trim(BENEFICIARY_VPA), '^') || '|' || coalesce(trim(BENEFICIARY_CREATED_DATE), '^') || '|' || coalesce(trim(BANK_NAME), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(trim(CREATED_LOAD_ID), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_beneficiary
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

