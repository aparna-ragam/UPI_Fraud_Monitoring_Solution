

    
    

    
    

    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    
        

        
            
            
        
    

    with cleansed as (
        select distinct
            trim(TRANSACTION_ID) as TRANSACTION_ID,
            trim(UPI_REF_NO) as UPI_REF_NO,
            trim(CUSTOMER_ID) as CUSTOMER_ID,
            trim(ACCOUNT_ID) as ACCOUNT_ID,
            trim(PAYER_VPA) as PAYER_VPA,
            trim(PAYEE_VPA) as PAYEE_VPA,
            trim(BENEFICIARY_ID) as BENEFICIARY_ID,
            trim(MERCHANT_ID) as MERCHANT_ID,
            trim(TXN_DATETIME) as TXN_DATETIME,
            trim(TXN_AMOUNT) as TXN_AMOUNT,
            trim(TXN_TYPE) as TXN_TYPE,
            trim(TXN_STATUS) as TXN_STATUS,
            trim(CHANNEL) as CHANNEL,
            trim(DEVICE_ID) as DEVICE_ID,
            trim(IP_ADDRESS) as IP_ADDRESS,
            trim(LATITUDE) as LATITUDE,
            trim(LONGITUDE) as LONGITUDE,
            trim(CREATED_LOAD_ID) as CREATED_LOAD_ID,
            CREATED_DATE_TIME,
            md5(coalesce(trim(TRANSACTION_ID), '^') || '|' || coalesce(trim(UPI_REF_NO), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(ACCOUNT_ID), '^') || '|' || coalesce(trim(PAYER_VPA), '^') || '|' || coalesce(trim(PAYEE_VPA), '^') || '|' || coalesce(trim(BENEFICIARY_ID), '^') || '|' || coalesce(trim(MERCHANT_ID), '^') || '|' || coalesce(trim(TXN_DATETIME), '^') || '|' || coalesce(trim(TXN_AMOUNT), '^') || '|' || coalesce(trim(TXN_TYPE), '^') || '|' || coalesce(trim(TXN_STATUS), '^') || '|' || coalesce(trim(CHANNEL), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(IP_ADDRESS), '^') || '|' || coalesce(trim(LATITUDE), '^') || '|' || coalesce(trim(LONGITUDE), '^') || '|' || coalesce(trim(CREATED_LOAD_ID), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
        from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_transaction
        where CREATED_LOAD_ID is not null
    )

    select *
    from cleansed
    where CREATED_LOAD_ID = (
        select max(CREATED_LOAD_ID)
        from cleansed
    )

