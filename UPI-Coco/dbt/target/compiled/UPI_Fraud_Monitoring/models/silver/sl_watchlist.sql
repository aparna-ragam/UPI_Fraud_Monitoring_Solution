

with source as (
    select
        cast(WATCHLIST_ID as VARCHAR(100)) as WATCHLIST_ID,
        cast(ENTITY_TYPE as VARCHAR(50)) as ENTITY_TYPE,
        cast(ENTITY_ID as VARCHAR(100)) as ENTITY_ID,
        cast(ENTITY_NAME as VARCHAR(255)) as ENTITY_NAME,
        cast(RISK_LEVEL as VARCHAR(20)) as RISK_LEVEL,
        cast(CREATED_LOAD_ID as NUMBER) as CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_watchlist
),

hashed as (
    select
        *,
        md5(
            coalesce(WATCHLIST_ID, '^') || '|' ||
            coalesce(ENTITY_TYPE, '^') || '|' ||
            coalesce(ENTITY_ID, '^') || '|' ||
            coalesce(ENTITY_NAME, '^') || '|' ||
            coalesce(RISK_LEVEL, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT,
        NULL::TIMESTAMP_NTZ as UPDATED_DATE_TIME,
        NULL::NUMBER as UPDATED_LOAD_ID
    from source
)



    select * from hashed

