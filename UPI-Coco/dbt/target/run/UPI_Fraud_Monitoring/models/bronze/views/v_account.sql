
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_account
  
   as (
    

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(ACCOUNT_ID) as ACCOUNT_ID,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(ACCOUNT_NUMBER) as ACCOUNT_NUMBER,
            trim(ACCOUNT_TYPE) as ACCOUNT_TYPE,
            trim(BRANCH_CODE) as BRANCH_CODE,
            trim(IFSC_CODE) as IFSC_CODE,
            trim(OPEN_DATE) as OPEN_DATE,
            trim(ACCOUNT_STATUS) as ACCOUNT_STATUS,
            trim(CURRENT_BALANCE) as CURRENT_BALANCE,
            trim(AVAILABLE_BALANCE) as AVAILABLE_BALANCE,
            CREATED_DATE_TIME,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(ACCOUNT_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(ACCOUNT_NUMBER), '^') || '|' || coalesce(trim(ACCOUNT_TYPE), '^') || '|' || coalesce(trim(BRANCH_CODE), '^') || '|' || coalesce(trim(IFSC_CODE), '^') || '|' || coalesce(trim(OPEN_DATE), '^') || '|' || coalesce(trim(ACCOUNT_STATUS), '^') || '|' || coalesce(trim(CURRENT_BALANCE), '^') || '|' || coalesce(trim(AVAILABLE_BALANCE), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_account
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )


  );

