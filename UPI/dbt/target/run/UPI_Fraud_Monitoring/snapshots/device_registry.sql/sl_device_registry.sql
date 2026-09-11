
      begin;
    merge into "UPI_FRAUD_MONITORING_DB"."TRANSFORM"."SL_DEVICE_REGISTRY" as DBT_INTERNAL_DEST
    using "UPI_FRAUD_MONITORING_DB"."TRANSFORM"."SL_DEVICE_REGISTRY__dbt_tmp" as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.scd_id = DBT_INTERNAL_DEST.scd_id

    when matched
     
       and DBT_INTERNAL_DEST.updated_date_time is null
     
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set updated_date_time = DBT_INTERNAL_SOURCE.updated_date_time

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert ("DEVICE_ID", "CUSTOMER_ID", "DEVICE_FINGERPRINT", "DEVICE_OS", "TRUSTED_FLAG", "DEVICE_AGE_DAYS", "DEVICE_RISK_SCORE", "CREATED_LOAD_ID", "DBT_UPDATED_AT", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "SCD_ID")
        values ("DEVICE_ID", "CUSTOMER_ID", "DEVICE_FINGERPRINT", "DEVICE_OS", "TRUSTED_FLAG", "DEVICE_AGE_DAYS", "DEVICE_RISK_SCORE", "CREATED_LOAD_ID", "DBT_UPDATED_AT", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "SCD_ID")

;
    commit;
  