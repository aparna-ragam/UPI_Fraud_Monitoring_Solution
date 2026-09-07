
with result_set as (
    select transaction_id, customer_id, account_id, 'FR001' as fraud_code, 90 as risk_score, 'HIGH_VALUE_UPI' as alert_type,created_date_time as load_dts
    from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction
    where is_current='TRUE' and txn_amount > 100000

    union all

    select transaction_id, customer_id, account_id, 'FR002' as fraud_code, 95 as risk_score, 'VELOCITY' as alert_type,created_date_time as load_dts
    from (
        SELECT transaction_id, customer_id, account_id,created_date_time,
               count(*) OVER (PARTITION BY CUSTOMER_ID ORDER BY TXN_DATETIME RANGE BETWEEN INTERVAL '5 MINUTE' PRECEDING AND CURRENT ROW) AS CNT
        FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction WHERE IS_CURRENT='TRUE'
    )
    WHERE CNT > 10

    UNION ALL

    SELECT T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID, 'FR005' as fraud_code, 80 as risk_score, 'NEW_DEVICE' as alert_type,T.created_date_time as load_dts
    FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction T
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_device_registry D ON T.DEVICE_ID = D.DEVICE_ID
    WHERE T.IS_CURRENT='TRUE' AND D.IS_CURRENT='TRUE' AND D.TRUSTED_FLAG = 'N'

    UNION ALL

    SELECT T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID, 'FR007' as fraud_code, 100 as risk_score, 'BLACKLISTED_BENEFICIARY' as alert_type,T.created_date_time as load_dts
    FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction T
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_beneficiary B ON T.BENEFICIARY_ID = B.BENEFICIARY_ID
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_watchlist W ON B.BENEFICIARY_NAME = W.ENTITY_NAME
    WHERE T.IS_CURRENT='TRUE' AND B.IS_CURRENT='TRUE' AND W.IS_CURRENT='TRUE'
),
rs as (SELECT UUID_STRING() AS ALERT_ID,
       r.fraud_code,
       f.fraud_name,
       r.transaction_id,
       r.customer_id,
       r.account_id,
       r.risk_score,
       r.alert_type,
       current_timestamp() as detected_ts,
       r.load_dts as load_ts,
       md5(
           coalesce(UUID_STRING(),'^') || '|' ||
           coalesce(r.fraud_code,'^') || '|' ||
           coalesce(f.fraud_name,'^') || '|' ||
           coalesce(r.transaction_id,'^') || '|' ||
           coalesce(r.customer_id,'^') || '|' ||
           coalesce(r.account_id,'^') || '|' ||
           coalesce(r.risk_score::text,'^') || '|' ||
           coalesce(r.load_dts::text,'^') || '|' ||
           coalesce(r.alert_type,'^')
       ) as hash_diff
from result_set r
left join UPI_FRAUD_MONITORING_DB.TRANSFORM.dim_fraud_rule f
  ON r.fraud_code = f.fraud_code)
select alert_id,
       fraud_code,
       fraud_name,
       transaction_id,
       customer_id,
       account_id,
       risk_score,
       alert_type,
       detected_ts,
       load_ts,
       hash_diff
from rs 

  