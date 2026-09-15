



select
    account_id,
    account_status,
    account_type,
    current_balance,
    available_balance,
    open_date,
    datediff(day, open_date, current_date) as account_age_days,
        case 
            when datediff(day, open_date, current_date) < 30 then 'HIGH'
            when current_balance > 1000000 then 'MEDIUM'
            else 'LOW'
        end as account_risk_rating,
        created_load_id    
from UPI_FRAUD_MONITORING_DB.TRANSFORM.v_account
