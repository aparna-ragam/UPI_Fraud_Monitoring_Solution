


with source as (
select
    b.beneficiary_id,
    customer_id,
    beneficiary_name,
    beneficiary_vpa,
    beneficiary_created_date,
    bank_name,
    case when exists(select 1 from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_watchlist w where w.entity_type='BENEFICIARY' and w.entity_id=b.beneficiary_id and w.is_current='TRUE' ) then 'HIGH'
         when t.txn_amount> 1000000 then 'HIGH'
	 when t.cnt> 10 then 'HIGH'
	 when datediff(Day,beneficiary_created_date,current_Date)< 30 then 'MEDIUM'
    else 'LOW' end as risk_rating,
    b.created_load_id,
    b.created_date_time,
    md5(
        coalesce(b.beneficiary_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
        coalesce(beneficiary_name,'^') || '|' ||
        coalesce(beneficiary_vpa,'^') || '|' ||
        coalesce(cast(beneficiary_created_date as varchar),'^') || '|' ||
        coalesce(bank_name,'^') || '|' ||
        coalesce(risk_rating,'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_beneficiary b
left join (select beneficiary_id,sum(txn_amount) as txn_amount,count(distinct customer_id) cnt from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_transaction where is_current='TRUE' group by beneficiary_id) t
on b.beneficiary_id=t.beneficiary_id
)

select
    beneficiary_id,
    customer_id,
    beneficiary_name,
    beneficiary_vpa,
    beneficiary_created_date,
    bank_name,
    risk_rating,
    hash_diff,
    created_load_id,
    created_date_time,
    null as updated_date_time,
    true as is_current
    from source


    
    where created_date_time > (select coalesce(max(created_date_time), '1900-01-01'::timestamp)
    from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_beneficiary)
    
