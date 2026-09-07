


with source as (
select
    account_id,
    customer_id,
    account_type,
    account_status,
    current_balance,
    available_balance,
    open_date,
    datediff(day,open_date,current_date) as account_age_days,
    case when account_age_days < 30 then 'HIGH'
         when current_balance > 1000000 then 'MEDIUM' 
	 else 'LOW' 
     end as account_risk_rating,
    created_load_id,
    created_date_time,
md5(
        coalesce(account_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
        coalesce(cast(account_type as varchar),'^') || '|' ||
        coalesce(account_status,'^') || '|' ||
        coalesce(cast(current_balance as varchar),'^') || '|' ||
        coalesce(cast(available_balance as varchar),'^') || '|' ||
	coalesce(cast(open_date as varchar),'^') || '|' ||
        coalesce(cast(account_age_days as varchar),'^') || '|' ||
        coalesce(cast(account_risk_rating as varchar),'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_account
)

select
    account_id,
    customer_id,
    account_type,
    account_status,
    current_balance,
    available_balance,
    open_date,
    account_age_days,
    account_risk_rating,
    hash_diff,
    created_load_id,
    created_date_time,
    null as updated_date_time,
    true as is_current
    from source



    
    where created_date_time > (select coalesce(max(created_date_time), '1900-01-01'::timestamp)
    from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_account)
    
