
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_merchant
  
  
  
  
  as (
    
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        MERCHANT_ID,
    MERCHANT_NAME,
    MERCHANT_CATEGORY,
    MERCHANT_STATUS,
    RISK_RATING,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.merchant

  );

