{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['login_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_login_activity') }} src
            where src.login_id = tgt.login_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    login_id,
    customer_id,
    device_id,
    login_time,
    login_status,
    country,
    state,
    city,
    ip_address,
    created_load_id,
md5(
        coalesce(login_id,'^') || '|' ||
        coalesce(customer_id,'^') || '|' ||
	coalesce(device_id,'^') || '|' ||
	coalesce(cast(login_time as varchar),'^') || '|' ||
        coalesce(cast(login_status as varchar),'^') || '|' ||
        coalesce(cast(country as varchar),'^') || '|' ||
        coalesce(cast(state as varchar),'^') || '|' ||
        coalesce(cast(city as varchar),'^') || '|' ||
        coalesce(cast(ip_address as varchar),'^')
    ) as hash_diff
from  {{ ref('v_login_activity') }}
)

select
    login_id,
    customer_id,
    device_id,
    login_time,
    login_status,
    country,
    state,
    city,
    ip_address,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source
