
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_watchlist
  
   as (
    

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(WATCHLIST_ID) as WATCHLIST_ID,
            trim(ENTITY_TYPE) as ENTITY_TYPE,
            trim(ENTITY_ID) as ENTITY_ID,
            trim(ENTITY_NAME) as ENTITY_NAME,
            trim(RISK_LEVEL) as RISK_LEVEL,
            CREATED_DATE_TIME,
            cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
            md5(coalesce(trim(WATCHLIST_ID), '^') || '|' || coalesce(trim(ENTITY_TYPE), '^') || '|' || coalesce(trim(ENTITY_ID), '^') || '|' || coalesce(trim(ENTITY_NAME), '^') || '|' || coalesce(trim(RISK_LEVEL), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_watchlist
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )


  );

