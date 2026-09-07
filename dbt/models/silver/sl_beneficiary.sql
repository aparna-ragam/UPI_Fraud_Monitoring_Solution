{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['beneficiary_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_beneficiary') }} src
            where src.beneficiary_id = tgt.beneficiary_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    b.beneficiary_id,
    customer_id,
    beneficiary_name,
    beneficiary_vpa,
    beneficiary_created_date,
    bank_name,
    case when exists(select 1 from {{ ref('sl_watchlist') }} w where w.entity_type='BENEFICIARY' and w.entity_id=b.beneficiary_id and w.is_current='TRUE' ) then 'HIGH'
         when t.txn_amount> 1000000 then 'HIGH'
	 when t.cnt> 10 then 'HIGH'
	 when datediff(Day,beneficiary_created_date,current_Date)< 30 then 'MEDIUM'
    else 'LOW' end as risk_rating,
    b.created_load_id,
    md5(
        coalesce(b.beneficiary_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
        coalesce(beneficiary_name,'^') || '|' ||
        coalesce(beneficiary_vpa,'^') || '|' ||
        coalesce(cast(beneficiary_created_date as varchar),'^') || '|' ||
        coalesce(bank_name,'^') || '|' ||
        coalesce(risk_rating,'^')
    ) as hash_diff
from  {{ ref('v_beneficiary') }} b
left join (select beneficiary_id,sum(txn_amount) as txn_amount,count(distinct customer_id) cnt from {{ ref('sl_transaction') }} where is_current='TRUE' group by beneficiary_id) t
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
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source
