
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select account_id
from UPI_FRAUD_MONITORING_DB.transform.sl_account
where account_id is null



  
  
      
    ) dbt_internal_test