{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['account_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_account') }} src
            where src.account_id = tgt.account_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    account_id,
    customer_id,
    account_type,
    account_status,
    current_balance,
    available_balance,
    open_date,
    datediff(day,open_date,current_date) as account_age_days,
    case when account_age_days < 30 then 'HIGH'
         when current_balance > 1000000 then 'MEDIUM' 
	 else 'LOW' 
     end as account_risk_rating,
    created_load_id,
md5(
        coalesce(account_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
        coalesce(cast(account_type as varchar),'^') || '|' ||
        coalesce(account_status,'^') || '|' ||
        coalesce(cast(current_balance as varchar),'^') || '|' ||
        coalesce(cast(available_balance as varchar),'^') || '|' ||
	coalesce(cast(open_date as varchar),'^') || '|' ||
        coalesce(cast(account_age_days as varchar),'^') || '|' ||
        coalesce(cast(account_risk_rating as varchar),'^')
    ) as hash_diff
from  {{ ref('v_account') }}
)

select
    account_id,
    customer_id,
    account_type,
    account_status,
    current_balance,
    available_balance,
    open_date,
    account_age_days,
    account_risk_rating,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source
