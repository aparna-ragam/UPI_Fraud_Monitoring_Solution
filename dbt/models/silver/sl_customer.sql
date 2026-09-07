{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['customer_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_customer') }} src
            where src.customer_id = tgt.customer_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


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
from  {{ ref('v_customer') }}
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
