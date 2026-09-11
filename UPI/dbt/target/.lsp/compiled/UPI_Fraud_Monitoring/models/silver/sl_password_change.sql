


with source as (
select
    password_change_id,
    v.customer_id as customer_id,
    change_time,
    change_channel,
    v.device_id as device_id,
    extract(hour from change_time) as change_hour,
    dayname(change_time) as change_day_of_week,
    d.device_risk_score as device_risk_score,
    case
        when device_risk_score >=80 then 'HIGH'
	when extract(hour from change_time) between 0 and 4 then 'MEDIUM'
    else 'LOW'
    end as password_change_risk,
    v.created_load_id,
md5(
    coalesce(password_change_id,'^') || '|' ||
    coalesce(v.customer_id,'^') || '|' ||
	coalesce(cast(change_time as varchar),'^') || '|' ||
	coalesce(change_channel,'^') || '|' ||
	coalesce(v.device_id,'^') || '|' ||
	coalesce(cast(change_hour as varchar),'^') || '|' ||
	coalesce(change_day_of_week,'^') || '|' ||
	coalesce(cast(d.device_risk_score as varchar),'^') || '|' ||
    coalesce(password_change_risk,'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_password_change v
join UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_device_registry d
on v.device_id=d.device_id and d.is_current=true
)

select
    password_change_id,
    customer_id,
    change_time,
    change_channel,
    device_id,
    change_hour,
    change_day_of_week,
    device_risk_score,
    password_change_risk,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source