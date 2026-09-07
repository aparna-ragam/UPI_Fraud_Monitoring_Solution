REQUEST_HOUR(Useful for detecting unusual transaction timings.)
---------------------------------------------------------------------------------------------
EXTRACT(HOUR FROM REQUEST_TIME)

------------------------------------------------------------------------------------------
REQUEST_DAY_OF_WEEK (Useful for behavioral analysis.)
----------------------------------------------------------------------------------------
DAYNAME(REQUEST_TIME)

----------------------------------------------------------------------------------
REQUEST_RISK_RATING(Derived based on fraud rules)
------------------------------------------------------------------------------
CASE  WHEN REQUEST_AMOUNT >= 100000  THEN 'HIGH'
            WHEN REQUEST_STATUS = 'FAILED'
THEN 'MEDIUM'
ELSE 'LOW'
END