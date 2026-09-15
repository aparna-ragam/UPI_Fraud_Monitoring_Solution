
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_customer
  
   as (
    

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(CUSTOMER_NAME) as CUSTOMER_NAME,
            trim(DOB) as DOB,
            trim(GENDER) as GENDER,
            trim(MOBILE_NUMBER) as MOBILE_NUMBER,
            trim(EMAIL_ID) as EMAIL_ID,
            trim(CUSTOMER_SEGMENT) as CUSTOMER_SEGMENT,
            trim(CUSTOMER_TYPE) as CUSTOMER_TYPE,
            trim(KYC_STATUS) as KYC_STATUS,
            trim(RISK_RATING) as RISK_RATING,
            trim(CUSTOMER_SINCE) as CUSTOMER_SINCE,
            trim(CUSTOMER_STATUS) as CUSTOMER_STATUS,
            CREATED_DATE_TIME,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(CUSTOMER_NAME), '^') || '|' || coalesce(trim(DOB), '^') || '|' || coalesce(trim(GENDER), '^') || '|' || coalesce(trim(MOBILE_NUMBER), '^') || '|' || coalesce(trim(EMAIL_ID), '^') || '|' || coalesce(trim(CUSTOMER_SEGMENT), '^') || '|' || coalesce(trim(CUSTOMER_TYPE), '^') || '|' || coalesce(trim(KYC_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(trim(CUSTOMER_SINCE), '^') || '|' || coalesce(trim(CUSTOMER_STATUS), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_customer
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )


  );

