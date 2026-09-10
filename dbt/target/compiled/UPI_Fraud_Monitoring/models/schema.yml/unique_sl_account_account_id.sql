
    
    

select
    account_id as unique_field,
    count(*) as n_records

from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_account
where account_id is not null
group by account_id
having count(*) > 1


