{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['password_change_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_password_change')}} src
            where src.password_change_id = tgt.password_change_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
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
    v.created_load_id,
md5(
    coalesce(password_change_id,'^') || '|' ||
    coalesce(v.customer_id,'^') || '|' ||
	coalesce(cast(change_time as varchar),'^') || '|' ||
	coalesce(change_channel,'^') || '|' ||
	coalesce(v.device_id,'^') || '|' ||
	coalesce(cast(change_hour as varchar),'^') || '|' ||
	coalesce(change_day_of_week,'^') || '|' ||
	coalesce(cast(d.device_risk_score as varchar),'^') || '|' ||
    coalesce(password_change_risk,'^')
    ) as hash_diff
from  {{ ref('v_password_change') }} v
join {{ ref('sl_device_registry') }} d
on v.device_id=d.device_id and d.is_current=true
)

select
    password_change_id,
    customer_id,
    change_time,
    change_channel,
    device_id,
    change_hour,
    change_day_of_week,
    device_risk_score,
    password_change_risk,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source