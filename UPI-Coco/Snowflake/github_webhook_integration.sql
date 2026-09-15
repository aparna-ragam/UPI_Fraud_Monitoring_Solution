-- =============================================================
-- GITHUB ACTIONS WEBHOOK INTEGRATION FOR DBT BUILD
-- =============================================================
-- This script creates the Snowflake objects needed to trigger
-- a GitHub Actions workflow from Snowflake after data loads.
-- =============================================================

USE ROLE ACCOUNTADMIN;
USE DATABASE UPI_FRAUD_MONITORING;
USE SCHEMA STAGING;

-- =============================================================
-- STEP 1: Create secret for GitHub PAT
-- =============================================================
-- Replace <your-github-pat> with your actual GitHub PAT (repo scope)
CREATE OR REPLACE SECRET GITHUB_WEBHOOK_SECRET
  TYPE = GENERIC_STRING
  SECRET_STRING = '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';


-- =============================================================
-- STEP 2: Create network rule for GitHub API
-- =============================================================
CREATE OR REPLACE NETWORK RULE GITHUB_API_NETWORK_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('api.github.com');


-- =============================================================
-- STEP 3: Create external access integration
-- =============================================================
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION GITHUB_WEBHOOK_EAI
  ALLOWED_NETWORK_RULES = (GITHUB_API_NETWORK_RULE)
  ALLOWED_AUTHENTICATION_SECRETS = (GITHUB_WEBHOOK_SECRET)
  ENABLED = TRUE;


-- =============================================================
-- STEP 4: Create stored procedure to trigger GitHub Actions
-- =============================================================
-- Replace 'aparna-ragam' and 'your-repo-name' with actual values
CREATE OR REPLACE PROCEDURE TRIGGER_DBT_BUILD_SP(LOAD_ID VARCHAR, FOLDERS_PROCESSED VARCHAR)
  RETURNS VARCHAR
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.11'
  PACKAGES = ('requests', 'snowflake-snowpark-python')
  HANDLER = 'trigger_dbt_build'
  EXTERNAL_ACCESS_INTEGRATIONS = (GITHUB_WEBHOOK_EAI)
  SECRETS = ('github_pat' = GITHUB_WEBHOOK_SECRET)
AS
$$
import requests
import json
import _snowflake

def trigger_dbt_build(session, load_id, folders_processed):
    token = _snowflake.get_generic_secret_string('github_pat')

    # Update these values
    owner = 'aparna-ragam'
    repo = 'UPI_Fraud_Monitoring_Solution'  # <-- Replace with your actual repo name

    url = f'https://api.github.com/repos/{owner}/{repo}/dispatches'

    headers = {
        'Authorization': f'token {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json'
    }

    payload = {
        'event_type': 'dbt-build',
        'client_payload': {
            'load_id': str(load_id),
            'folders_processed': str(folders_processed),
            'triggered_by': 'snowflake_task'
        }
    }

    response = requests.post(url, headers=headers, json=payload)

    if response.status_code == 204:
        return f'SUCCESS: GitHub Actions triggered for LOAD_ID={load_id}'
    else:
        return f'FAILED: HTTP {response.status_code} - {response.text}'
$$;


-- =============================================================
-- STEP 5: Test the webhook (run after setting up secrets)
-- =============================================================
-- CALL TRIGGER_DBT_BUILD_SP('TEST_001', '1');


-- =============================================================
-- SETUP: GitHub Repository Secrets
-- =============================================================
-- In your GitHub repo, go to Settings > Secrets and variables > Actions
-- Add these secrets:
--   SNOWFLAKE_ACCOUNT   = qy00958.ap-south-1.aws
--   SNOWFLAKE_USER      = ARAGAM
--   SNOWFLAKE_PASSWORD  = <your-snowflake-password>
