

with source as (
    select
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(CUSTOMER_NAME as VARCHAR(255)) as CUSTOMER_NAME,
        cast(CUSTOMER_SEGMENT as VARCHAR(50)) as CUSTOMER_SEGMENT,
        cast(KYC_STATUS as VARCHAR(30)) as KYC_STATUS,
        cast(RISK_RATING as VARCHAR(20)) as RISK_RATING,
        cast(CUSTOMER_STATUS as VARCHAR(30)) as CUSTOMER_STATUS,
        cast(CUSTOMER_SINCE as DATE) as CUSTOMER_SINCE,
        cast(CUSTOMER_TYPE as VARCHAR(50)) as CUSTOMER_TYPE,
        CREATED_LOAD_ID,
        CREATED_DATE_TIME
    from UPI_FRAUD_MONITORING.TRANSFORM.v_raw_customer
),

hashed as (
    select
        *,
        md5(
            coalesce(CUSTOMER_ID, '^') || '|' ||
            coalesce(CUSTOMER_NAME, '^') || '|' ||
            coalesce(CUSTOMER_SEGMENT, '^') || '|' ||
            coalesce(KYC_STATUS, '^') || '|' ||
            coalesce(RISK_RATING, '^') || '|' ||
            coalesce(CUSTOMER_STATUS, '^') || '|' ||
            coalesce(cast(CUSTOMER_SINCE as VARCHAR), '^') || '|' ||
            coalesce(CUSTOMER_TYPE, '^')
        ) as HASH_DIFF,
        'Y' as IS_CURRENT
    from source
)



    select * from hashed

