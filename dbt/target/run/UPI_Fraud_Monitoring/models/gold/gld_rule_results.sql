
  create or replace   view UPI_FRAUD_MONITORING_DB.TRANSFORM.gld_rule_results
  
  
  
  
  as (
    SELECT UUID_STRING() AS ALERT_ID,
       result_set.fraud_code,
       f.fraud_name,
       result_set.transaction_id,
       result_set.customer_id,
       result_set.account_id,
       result_set.risk_score,
       result_set.alert_type,
       current_timestamp() as detected_ts,
       current_timestamp() as load_ts
from (
    select transaction_id, customer_id, account_id, 'FR001' as fraud_code, 90 as risk_score, 'HIGH_VALUE_UPI' as alert_type
    from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction
    where is_current='TRUE' and txn_amount > 100000

    union all

    select transaction_id, customer_id, account_id, 'FR002' as fraud_code, 95 as risk_score, 'VELOCITY' as alert_type
    from (
        SELECT transaction_id, customer_id, account_id,
               count(*) OVER (PARTITION BY CUSTOMER_ID ORDER BY TXN_DATETIME RANGE BETWEEN INTERVAL '5 MINUTE' PRECEDING AND CURRENT ROW) AS CNT
        FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction WHERE IS_CURRENT='TRUE'
    )
    WHERE CNT > 10

    UNION ALL

    SELECT T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID, 'FR005' as fraud_code, 80 as risk_score, 'NEW_DEVICE' as alert_type
    FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction T
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_device_registry D ON T.DEVICE_ID = D.DEVICE_ID
    WHERE T.IS_CURRENT='TRUE' AND D.IS_CURRENT='TRUE' AND D.TRUSTED_FLAG = 'N'

    UNION ALL

    SELECT T.TRANSACTION_ID, T.CUSTOMER_ID, T.ACCOUNT_ID, 'FR007' as fraud_code, 100 as risk_score, 'BLACKLISTED_BENEFICIARY' as alert_type
    FROM UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction T
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_beneficiary B ON T.BENEFICIARY_ID = B.BENEFICIARY_ID
    JOIN UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_watchlist W ON B.BENEFICIARY_NAME = W.ENTITY_NAME
    WHERE T.IS_CURRENT='TRUE' AND B.IS_CURRENT='TRUE' AND W.IS_CURRENT='TRUE'
) result_set
LEFT JOIN dim_fraud_rule f
  ON result_set.FRAUD_CODE = f.FRAUD_CODE
  );

