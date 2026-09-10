
    
    

select
    customer_id as unique_field,
    count(*) as n_records

from UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_customer
where customer_id is not null
group by customer_id
having count(*) > 1


