{{ config(
    materialized='incremental',
    unique_key='hash_diff',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

with result_set as (SELECT
    ALERT_ID,
    fraud_code,
    CUSTOMER_ID,
    TRANSACTION_ID,
    RISK_SCORE,
    CASE
        WHEN RISK_SCORE >= 95 THEN 'CRITICAL'
        WHEN RISK_SCORE >= 85 THEN 'HIGH'
        WHEN RISK_SCORE >= 70 THEN 'MEDIUM'
        ELSE 'LOW'
    END as ALERT_SEVERITY,
    'OPEN' as ALERT_STATUS,
    md5(
        coalesce(ALERT_ID,'^') || '|' ||
        coalesce(fraud_code,'^') || '|' ||
        coalesce(CUSTOMER_ID,'^') || '|' ||
        coalesce(TRANSACTION_ID,'^') || '|' ||
        coalesce(RISK_SCORE,'^') || '|' ||
        coalesce(CASE
            WHEN RISK_SCORE >= 95 THEN 'CRITICAL'
            WHEN RISK_SCORE >= 85 THEN 'HIGH'
            WHEN RISK_SCORE >= 70 THEN 'MEDIUM'
            ELSE 'LOW'
        END,'^') || '|' ||
        coalesce('OPEN','^')
    ) as hash_diff,
    load_ts
FROM {{ref('gld_rule_results')}})
select alert_id,
       fraud_code,
       customer_id,
       transaction_id,
       risk_score,
       alert_severity,
       alert_status,
       hash_diff,
       load_ts
from result_set


{% if is_incremental() %}
    
    where load_ts > (select coalesce(max(load_ts), '1900-01-01'::timestamp)
    from {{ this }})
    
{% endif %} 