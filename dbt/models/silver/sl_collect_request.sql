{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['collect_request_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_collect_request') }} src
            where src.collect_request_id = tgt.collect_request_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


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
md5(
        coalesce(collect_request_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
	coalesce(request_amount,'^') || '|' ||
	coalesce(request_time,'^') || '|' ||
	coalesce(request_status,'^') || '|' ||
	coalesce(request_hour,'^') || '|' ||
        coalesce(request_risk_rating,'^')
    ) as hash_diff
from  {{ ref('v_collect_request') }}
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
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source