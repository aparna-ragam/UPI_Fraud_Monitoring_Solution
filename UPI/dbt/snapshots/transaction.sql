 -- depends_on: {{ ref('sl_device_registry') }}
 {% snapshot sl_transaction %}

{{
    config(
        target_schema='transform',
        unique_key='transaction_id',
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
        created_load_id    
from {{ ref('v_transaction') }}

{% endsnapshot %}