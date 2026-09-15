
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_password_change
  
   as (
    

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(PASSWORD_CHANGE_ID) as PASSWORD_CHANGE_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(CHANGE_TIME) as CHANGE_TIME,
            trim(CHANGE_CHANNEL) as CHANGE_CHANNEL,
            trim(DEVICE_ID) as DEVICE_ID,
            trim(CREATED_LOAD_ID) as CREATED_LOAD_ID,
            CREATED_DATE_TIME,
            md5(coalesce(trim(PASSWORD_CHANGE_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(CHANGE_TIME), '^') || '|' || coalesce(trim(CHANGE_CHANNEL), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(CREATED_LOAD_ID), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_password_change
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )


  );

