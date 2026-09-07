


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
         when device_id in (select distinct device_id from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_device_registry where trusted_flag='N') then 'UNTRUSTED_DEVICE'
         when merchant_id in (select distinct merchant_id from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_merchant where risk_rating='HIGH') then 'HIGH_RISK_MERCHANT'
         when customer_id in (select distinct customer_id from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_customer where risk_rating='HIGH') then 'HIGH_RISK_CUSTOMER'
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
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_transaction
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