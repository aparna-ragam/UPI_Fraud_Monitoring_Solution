{{
    config(
        materialized='incremental',
        incremental_strategy='append',
        on_schema_change='append_new_columns'
    )
}}

with alerts as (
    select
        cast(UUID_STRING() as VARCHAR(100)) as ALERT_ID,
        cast(RULE_ID as VARCHAR(20)) as RULE_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(TRANSACTION_ID as VARCHAR(100)) as TRANSACTION_ID,
        cast(RISK_SCORE as NUMBER) as RISK_SCORE,
        cast(
            CASE
                WHEN RISK_SCORE >= 95 THEN 'CRITICAL'
                WHEN RISK_SCORE >= 85 THEN 'HIGH'
                WHEN RISK_SCORE >= 70 THEN 'MEDIUM'
                ELSE 'LOW'
            END as VARCHAR(20)
        ) as SEVERITY,
        cast('OPEN' as VARCHAR(30)) as ALERT_STATUS,
        CREATED_DATE_TIME,
        CREATED_LOAD_ID
    from {{ ref('gld_rule_result') }}
)

{% if is_incremental() %}

    select a.*
    from alerts a
    left join {{ this }} t
        on a.TRANSACTION_ID = t.TRANSACTION_ID
        and a.RULE_ID = t.RULE_ID
    where t.ALERT_ID is null

{% else %}

    select * from alerts

{% endif %}
