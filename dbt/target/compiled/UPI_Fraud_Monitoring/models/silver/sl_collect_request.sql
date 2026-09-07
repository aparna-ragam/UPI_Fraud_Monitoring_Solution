


with source as (
select
    collect_request_id,
    customer_id,
    request_amount,
    request_time,
    request_status,
    extract(hour from request_time) as request_hour,
    dayname(request_time) as request_day_of_week,
    case when request_amount >= 100000 then 'HIGH' 
         when request_status= 'FAILED' then 'MEDIUM' 
	 else 'LOW'
    end as request_risk_rating,
    created_load_id,
    created_date_time,
md5(
        coalesce(collect_request_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
	coalesce(request_amount,'^') || '|' ||
	coalesce(request_time,'^') || '|' ||
	coalesce(request_status,'^') || '|' ||
	coalesce(request_hour,'^') || '|' ||
        coalesce(request_risk_rating,'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_collect_request
)

select
   collect_request_id,
    customer_id,
    request_amount,
    request_time,
    request_status,
    request_hour,
    request_day_of_week,
    request_risk_rating,
    hash_diff,
    created_load_id,
    created_date_time,
    null as updated_date_time,
    true as is_current
    from source


    
    where created_date_time > (select coalesce(max(created_date_time), '1900-01-01'::timestamp)
    from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_collect_request)
    
