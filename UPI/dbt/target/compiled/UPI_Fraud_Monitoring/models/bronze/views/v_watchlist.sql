
        
        with cleansed as (
            select distinct
                trim(WATCHLIST_ID) as WATCHLIST_ID,
    trim(ENTITY_TYPE) as ENTITY_TYPE,
    trim(ENTITY_ID) as ENTITY_ID,
    trim(ENTITY_NAME) as ENTITY_NAME,
    trim(RISK_LEVEL) as RISK_LEVEL,
    cast(CREATED_LOAD_ID as number(38,0)) as CREATED_LOAD_ID,
    CREATED_DATE_TIME,
                md5(coalesce(trim(WATCHLIST_ID), '^') || '|' || coalesce(trim(ENTITY_TYPE), '^') || '|' || coalesce(trim(ENTITY_ID), '^') || '|' || coalesce(trim(ENTITY_NAME), '^') || '|' || coalesce(trim(RISK_LEVEL), '^') || '|' || coalesce(cast(CREATED_LOAD_ID as string), '^') || '|' || coalesce(CREATED_DATE_TIME::string, '^')) as hash_diff
            from transform.v_raw_watchlist
            where created_load_id is not null
        )
        select *
        from cleansed
        where created_load_id = (
            select max(created_load_id)
            from cleansed
        )
    