
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_raw_login_activity
  
   as (
    

    
    

    select
        
        LOGIN_ID,
        
        CUSTOMER_ID,
        
        DEVICE_ID,
        
        LOGIN_TIME,
        
        LOGIN_STATUS,
        
        IP_ADDRESS,
        
        COUNTRY,
        
        STATE,
        
        CITY,
        
        CREATED_DATE_TIME,
        
        CREATED_LOAD_ID
        
    from UPI_FRAUD_MONITORING.STAGING.login_activity


  );

