
        
        with cleansed as (
            select distinct
                trim(CUSTOMER_SEGMENT) as CUSTOMER_SEGMENT,
    trim(CUSTOMER_TYPE) as CUSTOMER_TYPE,
    trim(KYC_STATUS) as KYC_STATUS,
    trim(RISK_RATING) as RISK_RATING,
    CUSTOMER_SINCE,
    trim(CUSTOMER_STATUS) as CUSTOMER_STATUS,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    trim(CUSTOMER_NAME) as CUSTOMER_NAME,
    DOB,
    trim(GENDER) as GENDER,
    cast(MOBILE_NUMBER as number(38,0)) as MOBILE_NUMBER,
    trim(EMAIL_ID) as EMAIL_ID,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
    trim(CUSTOMER_CITY) as CUSTOMER_CITY,
                md5(coalesce(trim(CUSTOMER_SEGMENT), '^') || '|' || coalesce(trim(CUSTOMER_TYPE), '^') || '|' || coalesce(trim(KYC_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(CUSTOMER_SINCE::string, '^') || '|' || coalesce(trim(CUSTOMER_STATUS), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(CUSTOMER_NAME), '^') || '|' || coalesce(DOB::string, '^') || '|' || coalesce(trim(GENDER), '^') || '|' || coalesce(cast(MOBILE_NUMBER as string), '^') || '|' || coalesce(trim(EMAIL_ID), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^') || '|' || coalesce(trim(CUSTOMER_CITY), '^')) as hash_diff
            from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_raw_customer
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    