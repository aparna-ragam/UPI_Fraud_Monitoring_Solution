{{ config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key=['transaction_id','hash_diff'],
    on_schema_change='append_new_columns',
    pre_hook=[
        "
        update {{ this }} as tgt
        set is_current = false,
            updated_date_time = current_timestamp()
        where exists (
            select 1
            from {{ ref('v_transaction')}} src
            where src.transaction_id = tgt.transaction_id
              and src.hash_diff <> tgt.hash_diff
              and tgt.is_current = true
        )
        "
    ]
) }}


with source as (
select
    transaction_id,
    customer_id,
    account_id,
    beneficiary_id,
    merchant_id,
    device_id,
    txn_datetime,
    txn_amount,
    txn_type,
    txn_status,
    channel,
    case when txn_amount>=100000 then 'HIGH_VALUE_TXN'
         when device_id in (select distinct device_id from {{ref('sl_device_registry')}} where trusted_flag='N') then 'UNTRUSTED_DEVICE'
         when merchant_id in (select distinct merchant_id from {{ref('sl_merchant')}} where risk_rating='HIGH') then 'HIGH_RISK_MERCHANT'
         when customer_id in (select distinct customer_id from {{ref('sl_customer')}} where risk_rating='HIGH') then 'HIGH_RISK_CUSTOMER'
	     when txn_status='FAILED' then 'FAILED TRANSACTION'
    else 'NORMAL'  end as txn_risk_reason,
    created_load_id,
md5(
    coalesce(transaction_id,'^') || '|' ||
    coalesce(customer_id,'^') || '|' ||
	coalesce(account_id,'^') || '|' ||
	coalesce(beneficiary_id,'^') || '|' ||
	coalesce(merchant_id,'^') || '|' ||
	coalesce(device_id,'^') || '|' ||
	coalesce(txn_datetime,'^') || '|' ||
	coalesce(txn_amount,'^') || '|' ||
	coalesce(txn_type,'^') || '|' ||
	coalesce(txn_status,'^') || '|' ||
	coalesce(channel,'^') || '|' ||
	coalesce(txn_risk_reason,'^')
    ) as hash_diff
from  {{ ref('v_transaction') }}
)

select
    transaction_id,
    customer_id,
    account_id,
    beneficiary_id,
    merchant_id,
    device_id,
    txn_datetime,
    txn_amount,
    txn_type,
    txn_status,
    channel,
    txn_risk_reason,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source