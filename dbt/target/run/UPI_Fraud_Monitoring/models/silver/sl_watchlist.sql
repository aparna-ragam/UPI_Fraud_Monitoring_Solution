-- back compat for old kwarg name
  
  begin;
    
        
            
                
                
            
                
                
            
        
    

    

    merge into UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_watchlist as DBT_INTERNAL_DEST
        using UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_watchlist__dbt_tmp as DBT_INTERNAL_SOURCE
        on (
                    DBT_INTERNAL_SOURCE.watchlist_id = DBT_INTERNAL_DEST.watchlist_id
                ) and (
                    DBT_INTERNAL_SOURCE.hash_diff = DBT_INTERNAL_DEST.hash_diff
                )

    
    when matched then update set
        "WATCHLIST_ID" = DBT_INTERNAL_SOURCE."WATCHLIST_ID","ENTITY_TYPE" = DBT_INTERNAL_SOURCE."ENTITY_TYPE","ENTITY_ID" = DBT_INTERNAL_SOURCE."ENTITY_ID","ENTITY_NAME" = DBT_INTERNAL_SOURCE."ENTITY_NAME","RISK_LEVEL" = DBT_INTERNAL_SOURCE."RISK_LEVEL","HASH_DIFF" = DBT_INTERNAL_SOURCE."HASH_DIFF","CREATED_LOAD_ID" = DBT_INTERNAL_SOURCE."CREATED_LOAD_ID","CREATED_DATE_TIME" = DBT_INTERNAL_SOURCE."CREATED_DATE_TIME","UPDATED_DATE_TIME" = DBT_INTERNAL_SOURCE."UPDATED_DATE_TIME","IS_CURRENT" = DBT_INTERNAL_SOURCE."IS_CURRENT"
    

    when not matched then insert
        ("WATCHLIST_ID", "ENTITY_TYPE", "ENTITY_ID", "ENTITY_NAME", "RISK_LEVEL", "HASH_DIFF", "CREATED_LOAD_ID", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "IS_CURRENT")
    values
        ("WATCHLIST_ID", "ENTITY_TYPE", "ENTITY_ID", "ENTITY_NAME", "RISK_LEVEL", "HASH_DIFF", "CREATED_LOAD_ID", "CREATED_DATE_TIME", "UPDATED_DATE_TIME", "IS_CURRENT")

;
    commit;