
      
  
    

create or replace transient table UPI_FRAUD_MONITORING_DB.transform.sl_account
    
    
    
    
    

    as (
    

    select *,
        md5(coalesce(cast(account_id as varchar ), '')
         || '|' || coalesce(cast(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as varchar ), '')
        ) as scd_id,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as dbt_updated_at,
        to_timestamp_ntz(convert_timezone('UTC', current_timestamp())) as created_date_time,
        
  
  coalesce(nullif(to_timestamp_ntz(convert_timezone('UTC', current_timestamp())), to_timestamp_ntz(convert_timezone('UTC', current_timestamp()))), null)
  as updated_date_time
from (
        



select
    account_id,
    account_status,
    account_type,
    current_balance,
    available_balance,
    open_date,
    datediff(day, open_date, current_date) as account_age_days,
        case 
            when datediff(day, open_date, current_date) < 30 then 'HIGH'
            when current_balance > 1000000 then 'MEDIUM'
            else 'LOW'
        end as account_risk_rating,
        created_load_id,
    created_date_time
from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_account

    ) sbq



    )
;


  
  