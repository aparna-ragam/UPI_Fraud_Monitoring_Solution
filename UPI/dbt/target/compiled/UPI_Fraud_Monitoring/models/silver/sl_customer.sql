


with source as (
select
    customer_id,
    customer_name,
    customer_segment,
    kyc_status,
    risk_rating,
    customer_status,
    customer_since,
    customer_type,
    created_load_id,
    md5(
        coalesce(customer_name,'^') || '|' ||
        coalesce(customer_segment,'^') || '|' ||
        coalesce(kyc_status,'^') || '|' ||
        coalesce(risk_rating,'^') || '|' ||
        coalesce(customer_status,'^') || '|' ||
        coalesce(customer_since,'^') || '|' ||
        coalesce(customer_type,'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_customer
)

select
    customer_id,
    customer_name,
    customer_segment,
    kyc_status,
    risk_rating,
    customer_status,
    customer_since,
    customer_type,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source