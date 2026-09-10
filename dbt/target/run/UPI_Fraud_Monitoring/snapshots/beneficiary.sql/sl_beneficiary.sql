
      begin;
    merge into "UPI_FRAUD_MONITORING_DB"."TRANSFORM"."SL_BENEFICIARY" as DBT_INTERNAL_DEST
    using "UPI_FRAUD_MONITORING_DB"."TRANSFORM"."SL_BENEFICIARY__dbt_tmp" as DBT_INTERNAL_SOURCE
    on DBT_INTERNAL_SOURCE.scd_id = DBT_INTERNAL_DEST.scd_id

    when matched
     
       and DBT_INTERNAL_DEST.updated_date_time is null
     
     and DBT_INTERNAL_SOURCE.dbt_change_type in ('update', 'delete')
        then update
        set updated_date_time = DBT_INTERNAL_SOURCE.updated_date_time

    when not matched
     and DBT_INTERNAL_SOURCE.dbt_change_type = 'insert'
        then insert ("BENEFICIARY_ID", "CUSTOMER_ID", "BENEFICIARY_NAME", "BENEFICIARY_VPA", "BENEFICIARY_CREATED_DATE", "BANK_NAME", "RISK_RATING", "CREATED_LOAD_ID", "DBT_UPDATED_AT", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "SCD_ID")
        values ("BENEFICIARY_ID", "CUSTOMER_ID", "BENEFICIARY_NAME", "BENEFICIARY_VPA", "BENEFICIARY_CREATED_DATE", "BANK_NAME", "RISK_RATING", "CREATED_LOAD_ID", "DBT_UPDATED_AT", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "SCD_ID")

;
    commit;
  