
        
        with cleansed as (
            select distinct
                trim(LOGIN_ID) as LOGIN_ID,
    trim(CUSTOMER_ID) as CUSTOMER_ID,
    trim(DEVICE_ID) as DEVICE_ID,
    LOGIN_TIME,
    trim(LOGIN_STATUS) as LOGIN_STATUS,
    trim(IP_ADDRESS) as IP_ADDRESS,
    trim(COUNTRY) as COUNTRY,
    trim(STATE) as STATE,
    trim(CITY) as CITY,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(LOGIN_ID), '^') || '|' || coalesce(trim(CUSTOMER_ID), '^') || '|' || coalesce(trim(DEVICE_ID), '^') || '|' || coalesce(LOGIN_TIME::string, '^') || '|' || coalesce(trim(LOGIN_STATUS), '^') || '|' || coalesce(trim(IP_ADDRESS), '^') || '|' || coalesce(trim(COUNTRY), '^') || '|' || coalesce(trim(STATE), '^') || '|' || coalesce(trim(CITY), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_login_activity
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    