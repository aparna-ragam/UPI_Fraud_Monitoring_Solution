-- =============================================================
-- UPI FRAUD MONITORING - NEAR REAL-TIME DATA INGESTION PIPELINE
-- =============================================================
--
-- Architecture:
-- S3 (upi-fraud-monitoring/Inbound/<folder>/*.csv)
--   -> Storage Integration -> External Stage
--   -> Single Snowpipe -> RAW_INGESTION_LOG (metadata table)
--   -> Stream -> Task (every 5 min) -> Stored Procedure
--   -> Dynamic target tables (one per folder)
--
-- =============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE UPI_FRAUD_MONITORING;
USE SCHEMA STAGING;

-- =============================================================
-- STEP 1: STORAGE INTEGRATION
-- =============================================================
CREATE OR REPLACE STORAGE INTEGRATION S3_UPI_FRAUD_INTEGRATION
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::796378119782:role/snowflake_s3_upi_fraud_role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://upi-fraud-monitoring-ai/Inbound/');

-- Run this to get Snowflake's IAM user ARN and External ID
-- You need these to update your AWS IAM role trust policy
DESC INTEGRATION S3_UPI_FRAUD_INTEGRATION;

-- >>> ACTION REQUIRED <<<
-- In AWS IAM, update the trust policy of snowflake_s3_role with:
--   "Principal": { "AWS": "<STORAGE_AWS_IAM_USER_ARN>" }
--   "Condition": { "StringEquals": { "sts:ExternalId": "<STORAGE_AWS_EXTERNAL_ID>" } }


-- =============================================================
-- STEP 2: FILE FORMAT
-- =============================================================
-- Raw format: treats entire CSV line as a single field
-- Actual CSV parsing happens in the stored procedure
CREATE OR REPLACE FILE FORMAT CSV_RAW_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = NONE
  SKIP_HEADER = 0;


-- =============================================================
-- STEP 3: EXTERNAL STAGE
-- =============================================================
CREATE OR REPLACE STAGE S3_UPI_STAGE
  STORAGE_INTEGRATION = S3_UPI_FRAUD_INTEGRATION
  URL = 's3://upi-fraud-monitoring-ai/Inbound/'
  FILE_FORMAT = CSV_RAW_FORMAT;

-- Verify stage access (run after updating IAM trust policy)
-- LIST @S3_UPI_STAGE;


-- =============================================================
-- STEP 4: RAW INGESTION LOG (METADATA TABLE)
-- =============================================================
CREATE OR REPLACE TABLE RAW_INGESTION_LOG (
  RAW_LINE        VARCHAR(16777216),
  SOURCE_FILE     VARCHAR,
  FILE_ROW_NUMBER NUMBER,
  FOLDER_NAME     VARCHAR,
  INGESTED_AT     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
  PROCESSED       BOOLEAN DEFAULT FALSE
);


-- =============================================================
-- STEP 4B: LOAD AUDIT TABLE
-- =============================================================
CREATE OR REPLACE TABLE LOAD_AUDIT (
  LOAD_ID         VARCHAR NOT NULL,
  FOLDER_NAME     VARCHAR,
  SOURCE_FILE     VARCHAR,
  ROWS_LOADED     NUMBER DEFAULT 0,
  LOAD_START_TIME TIMESTAMP_NTZ,
  LOAD_END_TIME   TIMESTAMP_NTZ,
  STATUS          VARCHAR DEFAULT 'IN_PROGRESS',
  ERROR_MESSAGE   VARCHAR,
  CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);


-- =============================================================
-- STEP 5: SINGLE SNOWPIPE
-- =============================================================
CREATE OR REPLACE PIPE UPI_INGEST_PIPE
  AUTO_INGEST = TRUE
AS
COPY INTO UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG
  (RAW_LINE, SOURCE_FILE, FILE_ROW_NUMBER, FOLDER_NAME)
FROM (
  SELECT
    $1,
    METADATA$FILENAME,
    METADATA$FILE_ROW_NUMBER,
    SPLIT_PART(METADATA$FILENAME, '/', 2)
  FROM @UPI_FRAUD_MONITORING.STAGING.S3_UPI_STAGE
)
FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = NONE SKIP_HEADER = 0);

-- Get the SQS queue ARN for S3 event notification setup
SHOW PIPES LIKE 'UPI_INGEST_PIPE' IN UPI_FRAUD_MONITORING.STAGING;
-- Note the 'notification_channel' column value


-- =============================================================
-- STEP 6: STREAM ON RAW_INGESTION_LOG
-- =============================================================
CREATE OR REPLACE STREAM RAW_INGESTION_STREAM
  ON TABLE UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG
  APPEND_ONLY = TRUE;


-- =============================================================
-- STEP 7: STORED PROCEDURE - DYNAMIC TABLE CREATION & LOADING
-- =============================================================
CREATE OR REPLACE PROCEDURE PROCESS_INGESTION_SP()
  RETURNS VARCHAR
  LANGUAGE JAVASCRIPT
  EXECUTE AS CALLER
AS
$$
  // Generate a unique batch LOAD_ID
  var id_rs = snowflake.execute({sqlText:
    "SELECT 'LOAD_' || TO_CHAR(CURRENT_TIMESTAMP(), 'YYYYMMDD_HH24MISS') || '_' || UUID_STRING() AS LOAD_ID"
  });
  id_rs.next();
  var batch_load_id = id_rs.getColumnValue(1);

  var folders_rs = snowflake.execute({sqlText:
    "SELECT DISTINCT FOLDER_NAME " +
    "FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG " +
    "WHERE PROCESSED = FALSE " +
    "AND FOLDER_NAME IS NOT NULL " +
    "AND TRIM(FOLDER_NAME) != ''"
  });

  var folders_processed = 0;
  var errors = [];

  while (folders_rs.next()) {
    var folder = folders_rs.getColumnValue(1);
    var safe_table = folder.toUpperCase().replace(/[^A-Z0-9_]/g, '_');
    var safe_folder = folder.replace(/'/g, "''");

    // Get distinct source files for this folder
    var files_rs = snowflake.execute({sqlText:
      "SELECT DISTINCT SOURCE_FILE FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG " +
      "WHERE FOLDER_NAME = '" + safe_folder + "' AND PROCESSED = FALSE"
    });

    var file_list = [];
    while (files_rs.next()) {
      file_list.push(files_rs.getColumnValue(1));
    }

    for (var f = 0; f < file_list.length; f++) {
      var source_file = file_list[f];
      var safe_file = source_file.replace(/'/g, "''");

      // Insert audit record: IN_PROGRESS
      snowflake.execute({sqlText:
        "INSERT INTO UPI_FRAUD_MONITORING.STAGING.LOAD_AUDIT " +
        "(LOAD_ID, FOLDER_NAME, SOURCE_FILE, LOAD_START_TIME, STATUS) " +
        "VALUES ('" + batch_load_id + "', '" + safe_folder + "', '" + safe_file + "', CURRENT_TIMESTAMP(), 'IN_PROGRESS')"
      });

      try {
        // Get header from first row of file
        var header_rs = snowflake.execute({sqlText:
          "SELECT RAW_LINE FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG " +
          "WHERE SOURCE_FILE = '" + safe_file + "' " +
          "AND FILE_ROW_NUMBER = 1 AND PROCESSED = FALSE LIMIT 1"
        });

        if (!header_rs.next()) continue;
        var header = header_rs.getColumnValue(1);
        if (!header || header.trim() === '') continue;

        // Parse column names from header
        var raw_cols = header.split(',');
        var cols = [];
        for (var i = 0; i < raw_cols.length; i++) {
          var col = raw_cols[i].trim().replace(/"/g, '').replace(/'/g, '');
          col = col.toUpperCase().replace(/[^A-Z0-9_ ]/g, '').replace(/ +/g, '_');
          if (col === '') col = 'COL_' + (i + 1);
          cols.push(col);
        }

        // Create target table with audit columns
        var col_defs = cols.map(function(c) { return '"' + c + '" VARCHAR'; }).join(', ');
        col_defs += ', "CREATED_LOAD_ID" VARCHAR, "CREATED_DATE_TIME" TIMESTAMP_NTZ';
        snowflake.execute({sqlText:
          'CREATE TABLE IF NOT EXISTS UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" (' + col_defs + ')'
        });

        // Enable schema evolution
        try {
          snowflake.execute({sqlText:
            'ALTER TABLE UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" SET ENABLE_SCHEMA_EVOLUTION = TRUE'
          });
        } catch(e) {}

        // Add new columns if schema has evolved
        for (var i = 0; i < cols.length; i++) {
          try {
            snowflake.execute({sqlText:
              'ALTER TABLE UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" ADD COLUMN IF NOT EXISTS "' + cols[i] + '" VARCHAR'
            });
          } catch(e) {}
        }

        // Ensure audit columns exist
        try {
          snowflake.execute({sqlText:
            'ALTER TABLE UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" ADD COLUMN IF NOT EXISTS "CREATED_LOAD_ID" VARCHAR'
          });
          snowflake.execute({sqlText:
            'ALTER TABLE UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" ADD COLUMN IF NOT EXISTS "CREATED_DATE_TIME" TIMESTAMP_NTZ'
          });
        } catch(e) {}

        // Insert data rows with LOAD_ID audit trail
        var col_list = cols.map(function(c) { return '"' + c + '"'; }).join(', ');
        col_list += ', "CREATED_LOAD_ID", "CREATED_DATE_TIME"';
        var val_list = cols.map(function(c, idx) {
          return "REPLACE(TRIM(SPLIT_PART(RAW_LINE, ',', " + (idx + 1) + ")), '\"', '')";
        }).join(', ');
        val_list += ", '" + batch_load_id + "', CURRENT_TIMESTAMP()";

        var insert_sql =
          'INSERT INTO UPI_FRAUD_MONITORING.STAGING."' + safe_table + '" (' + col_list + ') ' +
          'SELECT ' + val_list +
          ' FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG' +
          " WHERE SOURCE_FILE = '" + safe_file + "'" +
          ' AND FILE_ROW_NUMBER > 1' +
          ' AND PROCESSED = FALSE';

        snowflake.execute({sqlText: insert_sql});

        // Count rows loaded
        var count_rs = snowflake.execute({sqlText:
          "SELECT COUNT(*) FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG " +
          "WHERE SOURCE_FILE = '" + safe_file + "' AND FILE_ROW_NUMBER > 1 AND PROCESSED = FALSE"
        });
        count_rs.next();
        var rows_loaded = count_rs.getColumnValue(1);

        // Mark file rows as processed
        snowflake.execute({sqlText:
          "UPDATE UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG " +
          "SET PROCESSED = TRUE " +
          "WHERE SOURCE_FILE = '" + safe_file + "' AND PROCESSED = FALSE"
        });

        // Update audit: SUCCESS
        snowflake.execute({sqlText:
          "UPDATE UPI_FRAUD_MONITORING.STAGING.LOAD_AUDIT " +
          "SET STATUS = 'SUCCESS', ROWS_LOADED = " + rows_loaded + ", LOAD_END_TIME = CURRENT_TIMESTAMP() " +
          "WHERE LOAD_ID = '" + batch_load_id + "' AND SOURCE_FILE = '" + safe_file + "'"
        });

        folders_processed++;

      } catch(err) {
        // Update audit: FAILED
        var safe_err = err.message.replace(/'/g, "''").substring(0, 1000);
        snowflake.execute({sqlText:
          "UPDATE UPI_FRAUD_MONITORING.STAGING.LOAD_AUDIT " +
          "SET STATUS = 'FAILED', LOAD_END_TIME = CURRENT_TIMESTAMP(), ERROR_MESSAGE = '" + safe_err + "' " +
          "WHERE LOAD_ID = '" + batch_load_id + "' AND SOURCE_FILE = '" + safe_file + "'"
        });
        errors.push(folder + '/' + source_file + ': ' + err.message);
      }
    }
  }

  var result = folders_processed + ' file(s) processed | LOAD_ID: ' + batch_load_id;
  if (errors.length > 0) {
    result += ' | Errors: ' + errors.join('; ');
  }
  return result;
$$;


-- =============================================================
-- STEP 8: TASK (STREAM-TRIGGERED, NO SCHEDULE)
-- =============================================================
CREATE OR REPLACE TASK PROCESS_INGESTION_TASK
  WAREHOUSE = COMPUTE_WH
  WHEN SYSTEM$STREAM_HAS_DATA('UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_STREAM')
AS
  CALL UPI_FRAUD_MONITORING.STAGING.PROCESS_INGESTION_SP();

-- Resume the task (tasks are created in suspended state)
ALTER TASK PROCESS_INGESTION_TASK resume;


-- =============================================================
-- S3 EVENT NOTIFICATION SETUP (AWS Console)
-- =============================================================
-- 1. Run:  SHOW PIPES LIKE 'UPI_INGEST_PIPE' IN UPI_FRAUD_MONITORING.STAGING;
--    Copy the 'notification_channel' value (SQS queue ARN)
--
-- 2. In AWS Console > S3 > upi-fraud-monitoring-ai > Properties:
--    - Scroll to "Event notifications" > Create event notification
--    - Name:         snowpipe-upi-ingest
--    - Prefix:       Inbound/
--    - Suffix:       .csv
--    - Event types:  s3:ObjectCreated:*
--    - Destination:  SQS queue > Enter SQS queue ARN
--    - Paste the notification_channel ARN from step 1
--
-- Once configured, any CSV uploaded to s3://upi-fraud-monitoring-ai/Inbound/<folder>/
-- will be automatically ingested within 1-2 minutes via Snowpipe.
--
-- Note: Ensure the IAM role snowflake_s3_role has an S3 policy
-- granting access to the upi-fraud-monitoring-ai bucket.


-- =============================================================
-- VERIFICATION & MONITORING QUERIES
-- =============================================================

-- Check pipe status
-- SELECT SYSTEM$PIPE_STATUS('UPI_FRAUD_MONITORING.STAGING.UPI_INGEST_PIPE');

-- Check ingestion log
-- SELECT FOLDER_NAME, PROCESSED, COUNT(*) AS ROW_COUNT, MIN(INGESTED_AT) AS FIRST_INGESTED, MAX(INGESTED_AT) AS LAST_INGESTED
-- FROM UPI_FRAUD_MONITORING.STAGING.RAW_INGESTION_LOG
-- GROUP BY FOLDER_NAME, PROCESSED
-- ORDER BY FOLDER_NAME;

-- Check task run history
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(TASK_NAME => 'PROCESS_INGESTION_TASK'))
-- ORDER BY SCHEDULED_TIME DESC LIMIT 10;

-- List dynamically created tables
-- SHOW TABLES IN UPI_FRAUD_MONITORING.STAGING;

-- Manual test: call the procedure directly
-- CALL UPI_FRAUD_MONITORING.STAGING.PROCESS_INGESTION_SP();
