
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_watchlist
  
  
  
  
  as (
    
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        WATCHLIST_ID,
    ENTITY_TYPE,
    ENTITY_ID,
    ENTITY_NAME,
    RISK_LEVEL,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.watchlist

  );

