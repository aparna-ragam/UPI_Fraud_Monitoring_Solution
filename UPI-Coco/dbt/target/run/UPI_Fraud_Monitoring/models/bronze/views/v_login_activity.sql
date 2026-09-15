
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_login_activity
  
   as (
    

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(LOGIN_ID) as LOGIN_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(DEVICE_ID) as DEVICE_ID,
            trim(LOGIN_TIME) as LOGIN_TIME,
            trim(LOGIN_STATUS) as LOGIN_STATUS,
            trim(IP_ADDRESS) as IP_ADDRESS,
            trim(COUNTRY) as COUNTRY,
            trim(STATE) as STATE,
            trim(CITY) as CITY,
            CREATED_DATE_TIME,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(LOGIN_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(LOGIN_TIME), '^') || '|' || coalesce(trim(LOGIN_STATUS), '^') || '|' || coalesce(trim(IP_ADDRESS), '^') || '|' || coalesce(trim(COUNTRY), '^') || '|' || coalesce(trim(STATE), '^') || '|' || coalesce(trim(CITY), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_login_activity
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )


  );

