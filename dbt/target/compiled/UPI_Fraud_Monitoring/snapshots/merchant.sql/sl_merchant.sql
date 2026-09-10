



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
    created_load_id    
from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_merchant
