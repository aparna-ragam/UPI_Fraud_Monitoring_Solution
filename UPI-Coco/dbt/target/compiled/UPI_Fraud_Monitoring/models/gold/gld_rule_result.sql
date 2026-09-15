

with result_set as (

    -- FR001: High Value UPI Transaction
    select
        TRANSACTION_ID, CUSTOMER_ID, ACCOUNT_ID,
        'FR001' as RULE_ID,
        90 as RISK_SCORE,
        'HIGH_VALUE_UPI' as SEVERITY,
        CREATED_DATE_TIME,
        CREATED_LOAD_ID
    from UPI_FRAUD_MONITORING.TRANSFORM.sl_transaction
    where UPDATED_DATE_TIME is null
      and TXN_AMOUNT > 100000

    union all

    -- FR002: Velocity Breach (>10 txns within 5 min window)
    select
        TRANSACTION_ID, CUSTOMER_ID, ACCOUNT_ID,
        'FR002' as RULE_ID,
        95 as RISK_SCORE,
        'VELOCITY' as SEVERITY,
        CREATED_DATE_TIME,
        CREATED_LOAD_ID
    from (
        select
            TRANSACTION_ID, CUSTOMER_ID, ACCOUNT_ID,
            CREATED_DATE_TIME, CREATED_LOAD_ID,
            count(*) over (
                partition by CUSTOMER_ID
                order by TXN_DATETIME
                range between interval '5 MINUTE' preceding and current row
            ) as CNT
        from UPI_FRAUD_MONITORING.TRANSFORM.sl_transaction
        where UPDATED_DATE_TIME is null
    )
    where CNT > 10

    union all

    -- FR005: New/Untrusted Device
    select
        T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID,
        'FR005' as RULE_ID,
        80 as RISK_SCORE,
        'NEW_DEVICE' as SEVERITY,
        T.CREATED_DATE_TIME,
        T.CREATED_LOAD_ID
    from UPI_FRAUD_MONITORING.TRANSFORM.sl_transaction T
    join UPI_FRAUD_MONITORING.TRANSFORM.sl_device D
        on T.DEVICE_ID = D.DEVICE_ID
    where T.UPDATED_DATE_TIME is null
      and D.UPDATED_DATE_TIME is null
      and D.TRUSTED_FLAG = 'N'

    union all

    -- FR007: Blacklisted Beneficiary (watchlist match)
    select
        T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID,
        'FR007' as RULE_ID,
        100 as RISK_SCORE,
        'BLACKLISTED_BENEFICIARY' as SEVERITY,
        T.CREATED_DATE_TIME,
        T.CREATED_LOAD_ID
    from UPI_FRAUD_MONITORING.TRANSFORM.sl_transaction T
    join UPI_FRAUD_MONITORING.TRANSFORM.sl_beneficiary B
        on T.BENEFICIARY_ID = B.BENEFICIARY_ID
    join UPI_FRAUD_MONITORING.TRANSFORM.sl_watchlist W
        on B.BENEFICIARY_NAME = W.ENTITY_NAME
    where T.UPDATED_DATE_TIME is null
      and B.UPDATED_DATE_TIME is null
      and W.UPDATED_DATE_TIME is null

),

enriched as (
    select
        cast(UUID_STRING() as VARCHAR(100)) as RULE_RESULT_ID,
        cast(r.RULE_ID as VARCHAR(20)) as RULE_ID,
        cast(f.FRAUD_NAME as VARCHAR(200)) as RULE_NAME,
        cast(r.TRANSACTION_ID as VARCHAR(100)) as TRANSACTION_ID,
        cast(r.CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(r.ACCOUNT_ID as VARCHAR(50)) as ACCOUNT_ID,
        cast(r.RISK_SCORE as NUMBER) as RISK_SCORE,
        cast(r.SEVERITY as VARCHAR(20)) as SEVERITY,
        cast('ACTIVE' as VARCHAR(20)) as RULE_STATUS,
        CURRENT_TIMESTAMP()::TIMESTAMP_NTZ as DETECTED_TS,
        r.CREATED_DATE_TIME,
        r.CREATED_LOAD_ID
    from result_set r
    left join UPI_FRAUD_MONITORING.TRANSFORM.dim_fraud_rule f
        on r.RULE_ID = f.FRAUD_CODE
)



    select * from enriched

