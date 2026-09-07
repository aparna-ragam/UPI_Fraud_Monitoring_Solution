
        
        with cleansed as (
            select distinct
                trim(ACCOUNT_ID) as ACCOUNT_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    cast(ACCOUNT_NUMBER as number(38,0)) as ACCOUNT_NUMBER,
    trim(ACCOUNT_TYPE) as ACCOUNT_TYPE,
    trim(BRANCH_CODE) as BRANCH_CODE,
    trim(IFSC_CODE) as IFSC_CODE,
    OPEN_DATE,
    trim(ACCOUNT_STATUS) as ACCOUNT_STATUS,
    cast(CURRENT_BALANCE as number(38,0)) as CURRENT_BALANCE,
    cast(AVAILABLE_BALANCE as number(38,0)) as AVAILABLE_BALANCE,
    trim(SOURCE_FILE_NAME) as SOURCE_FILE_NAME,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(ACCOUNT_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(cast(ACCOUNT_NUMBER as string), '^') || '|' || coalesce(trim(ACCOUNT_TYPE), '^') || '|' || coalesce(trim(BRANCH_CODE), '^') || '|' || coalesce(trim(IFSC_CODE), '^') || '|' || coalesce(OPEN_DATE::string, '^') || '|' || coalesce(trim(ACCOUNT_STATUS), '^') || '|' || coalesce(cast(CURRENT_BALANCE as string), '^') || '|' || coalesce(cast(AVAILABLE_BALANCE as string), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_account
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    