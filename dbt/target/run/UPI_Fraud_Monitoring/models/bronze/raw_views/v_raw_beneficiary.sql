
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_beneficiary
  
  
  
  
  as (
    
    
    

    
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    
        
    

    select
        BENEFICIARY_ID,
    CUSTOMER_ID,
    BENEFICIARY_NAME,
    BENEFICIARY_VPA,
    BENEFICIARY_CREATED_DATE,
    BANK_NAME,
    RISK_RATING,
    SOURCE_FILE_NAME,
    CREATED_LOAD_ID,
    CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING_DB.STAGING.beneficiary_master

  );

