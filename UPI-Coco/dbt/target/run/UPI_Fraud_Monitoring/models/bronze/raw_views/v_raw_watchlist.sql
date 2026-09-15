
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_raw_watchlist
  
   as (
    

    
    

    select
        
        WATCHLIST_ID,
        
        ENTITY_TYPE,
        
        ENTITY_ID,
        
        ENTITY_NAME,
        
        RISK_LEVEL,
        
        CREATED_DATE_TIME,
        
        CREATED_LOAD_ID
        
    from UPI_FRAUD_MONITORING.STAGING.watchlist


  );

