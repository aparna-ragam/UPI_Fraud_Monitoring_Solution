
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_password_change
  
  
  
  
  as (
    
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        PASSWORD_CHANGE_ID,
    CUSTOMER_ID,
    CHANGE_TIME,
    CHANGE_CHANNEL,
    DEVICE_ID,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.password_change

  );

