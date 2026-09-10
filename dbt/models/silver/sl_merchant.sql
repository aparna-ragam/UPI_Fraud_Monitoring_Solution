{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['merchant_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_merchant') }} src
            where src.merchant_id = tgt.merchant_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    merchant_id,
    merchant_name,
    merchant_category,
    case
        when merchant_category='Grocery' then '5411'
        when merchant_category='Fuel' then '5541'
        when merchant_category='Retail' then '6000'
    else 9999
    end as merchant_code,
    merchant_status,
    case 
        when merchant_code in ('5411','5541','5812') then 'LOW'
        when merchant_code in ('6000') then 'MEDIUM'
    else 'HIGH_RISK'
    end as risk_rating,
    created_load_id,
md5(
        coalesce(merchant_id,'^') || '|' ||
        coalesce(merchant_name,'^') || '|' ||
	coalesce(merchant_category,'^') || '|' ||
	coalesce(merchant_code,'^') || '|' ||
	coalesce(merchant_status,'^') || '|' ||
        coalesce(risk_rating,'^')
    ) as hash_diff
from  {{ ref('v_merchant') }}
)

select
    merchant_id,
    merchant_name,
    merchant_category,
    merchant_code,
    merchant_status,
    risk_rating,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source
