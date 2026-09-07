-- back compat for old kwarg name
  
  begin;
    
        
            
            
            
            
        
    

    

    merge into UPI_FRAUD_MONITORING_DB.analytics.gld_fraud_alert as DBT_INTERNAL_DEST
        using UPI_FRAUD_MONITORING_DB.analytics.gld_fraud_alert__dbt_tmp as DBT_INTERNAL_SOURCE
        on ((DBT_INTERNAL_SOURCE.hash_diff = DBT_INTERNAL_DEST.hash_diff))

    
    when matched then update set
        "ALERT_ID" = DBT_INTERNAL_SOURCE."ALERT_ID","FRAUD_CODE" = DBT_INTERNAL_SOURCE."FRAUD_CODE","CUSTOMER_ID" = DBT_INTERNAL_SOURCE."CUSTOMER_ID","TRANSACTION_ID" = DBT_INTERNAL_SOURCE."TRANSACTION_ID","RISK_SCORE" = DBT_INTERNAL_SOURCE."RISK_SCORE","ALERT_SEVERITY" = DBT_INTERNAL_SOURCE."ALERT_SEVERITY","ALERT_STATUS" = DBT_INTERNAL_SOURCE."ALERT_STATUS","HASH_DIFF" = DBT_INTERNAL_SOURCE."HASH_DIFF","LOAD_TS" = DBT_INTERNAL_SOURCE."LOAD_TS"
    

    when not matched then insert
        ("ALERT_ID", "FRAUD_CODE", "CUSTOMER_ID", "TRANSACTION_ID", "RISK_SCORE", "ALERT_SEVERITY", "ALERT_STATUS", "HASH_DIFF", "LOAD_TS")
    values
        ("ALERT_ID", "FRAUD_CODE", "CUSTOMER_ID", "TRANSACTION_ID", "RISK_SCORE", "ALERT_SEVERITY", "ALERT_STATUS", "HASH_DIFF", "LOAD_TS")

;
    commit;