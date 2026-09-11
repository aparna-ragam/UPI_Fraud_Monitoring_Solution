{% snapshot sl_beneficiary %}

{{
    config(
        target_schema='transform',
        unique_key='beneficiary_id',
        strategy='check',
        check_cols = 'all',
        snapshot_meta_column_names={
        "dbt_valid_from": "created_date_time",
        "dbt_valid_to": "updated_date_time",
        "dbt_scd_id": "scd_id",
        "dbt_is_current": "is_current"
        }
    )
}}

select
    b.beneficiary_id,
    customer_id,
    beneficiary_name,
    beneficiary_vpa,
    beneficiary_created_date,
    bank_name,
    case when exists(select 1 from {{ ref('sl_watchlist') }} w where w.entity_type='BENEFICIARY' and w.entity_id=b.beneficiary_id ) then 'HIGH'
         when t.txn_amount> 1000000 then 'HIGH'
	 when t.cnt> 10 then 'HIGH'
	 when datediff(Day,beneficiary_created_date,current_Date)< 30 then 'MEDIUM'
    else 'LOW' end as risk_rating,
    b.created_load_id   
from  {{ ref('v_beneficiary') }} b
left join (select beneficiary_id,sum(txn_amount) as txn_amount,count(distinct customer_id) cnt from {{ ref('sl_transaction') }}  group by beneficiary_id) t
on b.beneficiary_id=t.beneficiary_id

{% endsnapshot %}