
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_raw_password_change
  
   as (
    

    
    

    select
        
        PASSWORD_CHANGE_ID,
        
        CUSTOMER_ID,
        
        CHANGE_TIME,
        
        CHANGE_CHANNEL,
        
        DEVICE_ID,
        
        CREATED_DATE_TIME,
        
        CREATED_LOAD_ID
        
    from UPI_FRAUD_MONITORING.STAGING.password_change


  );

