



select
    b.beneficiary_id,
    customer_id,
    beneficiary_name,
    beneficiary_vpa,
    beneficiary_created_date,
    bank_name,
    case when exists(select 1 from UPI_FRAUD_MONITORING_DB.transform.sl_watchlist w where w.entity_type='BENEFICIARY' and w.entity_id=b.beneficiary_id ) then 'HIGH'
         when t.txn_amount> 1000000 then 'HIGH'
	 when t.cnt> 10 then 'HIGH'
	 when datediff(Day,beneficiary_created_date,current_Date)< 30 then 'MEDIUM'
    else 'LOW' end as risk_rating,
    b.created_load_id   
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_beneficiary b
left join (select beneficiary_id,sum(txn_amount) as txn_amount,count(distinct customer_id) cnt from UPI_FRAUD_MONITORING_DB.transform.sl_transaction  group by beneficiary_id) t
on b.beneficiary_id=t.beneficiary_id
