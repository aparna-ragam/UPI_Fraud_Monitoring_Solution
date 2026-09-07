
        
        with cleansed as (
            select distinct
                trim(BENEFICIARY_ID) as BENEFICIARY_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    trim(BENEFICIARY_NAME) as BENEFICIARY_NAME,
    trim(BENEFICIARY_VPA) as BENEFICIARY_VPA,
    BENEFICIARY_CREATED_DATE,
    trim(BANK_NAME) as BANK_NAME,
    trim(RISK_RATING) as RISK_RATING,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(BENEFICIARY_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(BENEFICIARY_NAME), '^') || '|' || coalesce(trim(BENEFICIARY_VPA), '^') || '|' || coalesce(BENEFICIARY_CREATED_DATE::string, '^') || '|' || coalesce(trim(BANK_NAME), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_beneficiary
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    