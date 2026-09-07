
  
    

create or replace transient table UPI_FRAUD_MONITORING_DB.TRANSFORM.sl_account
    
    
    
    
    

    as (ACCOUNT_AGE_DAYS
-------------------------------
DATEDIFF(
    DAY,
    OPEN_DATE,
    CURRENT_DATE
) AS ACCOUNT_AGE_DAYS

ACCOUNT_RISK_RATING
-----------------------------------
CASE
    WHEN ACCOUNT_AGE_DAYS < 30
         THEN 'HIGH'

    WHEN CURRENT_BALANCE > 1000000
         THEN 'MEDIUM'

    ELSE 'LOW'
END AS ACCOUNT_RISK_RATING
    )
;


  