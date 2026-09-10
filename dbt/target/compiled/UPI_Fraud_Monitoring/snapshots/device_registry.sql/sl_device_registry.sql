



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
        created_load_id    
from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_device_registry
