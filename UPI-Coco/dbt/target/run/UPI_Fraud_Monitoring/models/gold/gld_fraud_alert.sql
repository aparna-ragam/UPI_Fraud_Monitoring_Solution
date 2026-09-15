
  
    

        create or replace transient table UPI_FRAUD_MONITORING.ANALYTICS.gld_fraud_alert
          
  (
    ALERT_ID VARCHAR(100) not null,
    RULE_ID VARCHAR(20),
    CUSTOMER_ID VARCHAR(50),
    TRANSACTION_ID VARCHAR(100),
    RISK_SCORE NUMBER(38,0),
    SEVERITY VARCHAR(20),
    ALERT_STATUS VARCHAR(30),
    CREATED_DATE_TIME TIMESTAMP_NTZ,
    CREATED_LOAD_ID NUMBER(38,0)
    
    )

          
        
         as
        (
    select ALERT_ID, RULE_ID, CUSTOMER_ID, TRANSACTION_ID, RISK_SCORE, SEVERITY, ALERT_STATUS, CREATED_DATE_TIME, CREATED_LOAD_ID
    from (
        

with alerts as (
    select
        cast(UUID_STRING() as VARCHAR(100)) as ALERT_ID,
        cast(RULE_ID as VARCHAR(20)) as RULE_ID,
        cast(CUSTOMER_ID as VARCHAR(50)) as CUSTOMER_ID,
        cast(TRANSACTION_ID as VARCHAR(100)) as TRANSACTION_ID,
        cast(RISK_SCORE as NUMBER) as RISK_SCORE,
        cast(
            CASE
                WHEN RISK_SCORE >= 95 THEN 'CRITICAL'
                WHEN RISK_SCORE >= 85 THEN 'HIGH'
                WHEN RISK_SCORE >= 70 THEN 'MEDIUM'
                ELSE 'LOW'
            END as VARCHAR(20)
        ) as SEVERITY,
        cast('OPEN' as VARCHAR(30)) as ALERT_STATUS,
        CREATED_DATE_TIME,
        CREATED_LOAD_ID
    from UPI_FRAUD_MONITORING.ANALYTICS.gld_rule_result
)



    select * from alerts


    ) as model_subq
        );
      
  