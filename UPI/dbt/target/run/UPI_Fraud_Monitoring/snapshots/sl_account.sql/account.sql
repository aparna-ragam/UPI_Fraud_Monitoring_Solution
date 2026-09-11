
      
  
    

create or replace transient table UPI_FRAUD_MONITORING_DB.transform.account
    
    
    
    
    

    as (
    

    select *,
        md5(coalesce(cast(account_id as varchar ), '')
         || '|' || coalesce(cast(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as varchar ), '')
        ) as dbt_scd_id,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_updated_at,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_valid_from,
        
  
  coalesce(nullif(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())), to_timestamp_ntz(convert_timezone('UTC', current_timestamp()))), null)
  as dbt_valid_to
from (
        



select
    account_id,
    account_status,
    account_type,
    current_balance,
    available_balance,
    open_date,
    created_date_time
from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_account

    ) sbq



    )
;


  
  