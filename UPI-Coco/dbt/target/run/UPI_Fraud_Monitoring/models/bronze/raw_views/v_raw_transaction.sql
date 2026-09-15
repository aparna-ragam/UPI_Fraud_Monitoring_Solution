
  create or replace   view UPI_FRAUD_MONITORING.TRANSFORM.v_raw_transaction
  
   as (
    

    
    

    select
        
        TRANSACTION_ID,
        
        UPI_REF_NO,
        
        CUSTOMER_ID,
        
        ACCOUNT_ID,
        
        PAYER_VPA,
        
        PAYEE_VPA,
        
        BENEFICIARY_ID,
        
        MERCHANT_ID,
        
        TXN_DATETIME,
        
        TXN_AMOUNT,
        
        TXN_TYPE,
        
        TXN_STATUS,
        
        CHANNEL,
        
        DEVICE_ID,
        
        IP_ADDRESS,
        
        LATITUDE,
        
        LONGITUDE,
        
        CREATED_DATE_TIME,
        
        CREATED_LOAD_ID
        
    from UPI_FRAUD_MONITORING.STAGING.transaction


  );

