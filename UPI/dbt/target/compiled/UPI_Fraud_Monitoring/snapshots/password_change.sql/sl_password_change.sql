



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
        v.created_load_id    
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_password_change v
join UPI_FRAUD_MONITORING_DB.transform.sl_device_registry d
on v.device_id=d.device_id 
