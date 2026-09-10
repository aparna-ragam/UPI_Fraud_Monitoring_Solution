


with source as (
select
    device_id,
    customer_id,
    device_fingerprint,
    device_os,
    trusted_flag,
    datediff(day,DEVICE_REGISTRATION_DATE,current_date) as device_age_days,
    case when trusted_flag = 'N' then 40
         when device_age_days < 30 then 30 
	 else 0 
     end as device_risk_score,
    created_load_id,
md5(
        coalesce(device_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
	coalesce(device_fingerprint,'^') || '|' ||
	coalesce(device_os,'^') || '|' ||
        coalesce(cast(trusted_flag as varchar),'^') || '|' ||
        coalesce(cast(device_age_days as varchar),'^') || '|' ||
        coalesce(cast(device_risk_score as varchar),'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_device_registry
)

select
    device_id,
    customer_id,
    device_fingerprint,
    device_os,
    trusted_flag,
    device_age_days,
    device_risk_score,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source