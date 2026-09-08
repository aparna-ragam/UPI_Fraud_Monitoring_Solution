
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_customer
  
  
  
  
  as (
    
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        CUSTOMER_ID,
    CUSTOMER_NAME,
    DOB,
    GENDER,
    MOBILE_NUMBER,
    EMAIL_ID,
    CUSTOMER_SEGMENT,
    CUSTOMER_TYPE,
    KYC_STATUS,
    RISK_RATING,
    CUSTOMER_SINCE,
    CUSTOMER_STATUS,
    SOURCE_FILE_NAME,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.customer_master

  );

