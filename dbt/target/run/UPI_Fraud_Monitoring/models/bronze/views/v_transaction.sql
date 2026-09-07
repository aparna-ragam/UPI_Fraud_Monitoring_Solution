
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.v_transaction
  
  
  
  
  as (
    
        
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
    TXN_DATETIME,
    cast(TXN_AMOUNT as number(38,0)) as TXN_AMOUNT,
    trim(TXN_TYPE) as TXN_TYPE,
    trim(TXN_STATUS) as TXN_STATUS,
    trim(CHANNEL) as CHANNEL,
    trim(DEVICE_ID) as DEVICE_ID,
    trim(IP_ADDRESS) as IP_ADDRESS,
    cast(LATITUDE as number(38,0)) as LATITUDE,
    cast(LONGITUDE as number(38,0)) as LONGITUDE,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(TRANSACTION_ID), '^') || '|' || coalesce(trim(UPI_REF_NO), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(ACCOUNT_ID), '^') || '|' || coalesce(trim(PAYER_VPA), '^') || '|' || coalesce(trim(PAYEE_VPA), '^') || '|' || coalesce(trim(BENEFICIARY_ID), '^') || '|' || coalesce(trim(MERCHANT_ID), '^') || '|' || coalesce(TXN_DATETIME::string, '^') || '|' || coalesce(cast(TXN_AMOUNT as string), '^') || '|' || coalesce(trim(TXN_TYPE), '^') || '|' || coalesce(trim(TXN_STATUS), '^') || '|' || coalesce(trim(CHANNEL), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(trim(IP_ADDRESS), '^') || '|' || coalesce(cast(LATITUDE as string), '^') || '|' || coalesce(cast(LONGITUDE as string), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_transaction
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    
  );

