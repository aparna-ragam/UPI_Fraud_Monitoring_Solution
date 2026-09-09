-- =============================================================================
-- Environment Setup 
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- STEP 1: Create a warehouse 
-- =============================================================================

CREATE WAREHOUSE UPI_FRAUD_MONITORING_WH WAREHOUSE_SIZE = XSMALL;

-- =============================================================================
-- STEP 2: Create a database and schemas.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS UPI_FRAUD_MONITORING_DB;
CREATE SCHEMA IF NOT EXISTS UPI_FRAUD_MONITORING_DB.STAGING;
CREATE SCHEMA IF NOT EXISTS UPI_FRAUD_MONITORING_DB.TRANSFORM;
CREATE SCHEMA IF NOT EXISTS UPI_FRAUD_MONITORING_DB.ANALYTICS;

-- Used for storing objects Snowflake needs for GitHub integration (secrets, etc.)
CREATE SCHEMA IF NOT EXISTS UPI_FRAUD_MONITORING_DB.INTEGRATIONS;

--API integration is used to connect Snowflake to GitHub repository
CREATE OR REPLACE API INTEGRATION upi_dbt_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com')
  -- Comment out the following line if your forked repository is public
  --ALLOWED_AUTHENTICATION_SECRETS = ()
  ENABLED = TRUE;

  USE ROLE accountadmin;

  --CREATE STAGE 
  CREATE STAGE UPI_FRAUD_MONITORING_STG;

  --CREATE FILE FORMAT
  CREATE OR REPLACE FILE FORMAT UPI_FRD_MONITORING_CSV_FORMAT
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  PARSE_HEADER=TRUE,
  SKIP_HEADER = 0
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  NULL_IF = ('NULL', 'null');

--Create load_id sequence
CREATE OR REPLACE SEQUENCE UPI_FRAUD_MONITORING_DB.STAGING.LOAD_ID_SEQ
START = 1
INCREMENT = 1;

--Audit table
CREATE TABLE IF NOT EXISTS TESTING.FILE_LOAD_AUDIT
(
LOAD_ID NUMBER,
TABLE_NAME VARCHAR,
FILE_NAME VARCHAR,
ROWS_LOADED NUMBER,
LOAD_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
