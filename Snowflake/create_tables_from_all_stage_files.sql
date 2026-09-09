CREATE OR REPLACE PROCEDURE CREATE_TABLES_FROM_ALL_STAGE_FILES
(
    P_STAGE_NAME VARCHAR,
    P_FILE_FORMAT_NAME VARCHAR,
    P_TARGET_SCHEMA VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE

    LOAD_ID NUMBER;
    PROC_START_TIME TIMESTAMP_NTZ;

    PROCESSED_COUNT NUMBER DEFAULT 0;
    TABLE_EXISTS NUMBER;

    TABLE_NAME STRING;
    FOLDER_NAME STRING;
    FOLDER_PATH STRING;

    CREATE_TABLE_DDL STRING;
    COPY_INTO_DDL STRING;

    RS RESULTSET;

BEGIN

    ------------------------------------------------------------------
    -- Procedure Start Time
    ------------------------------------------------------------------
    PROC_START_TIME := CURRENT_TIMESTAMP();

    ------------------------------------------------------------------
    -- Generate Load ID
    ------------------------------------------------------------------
    SELECT UPI_FRAUD_MONITORING_DB.STAGING.LOAD_ID_SEQ.NEXTVAL
    INTO :LOAD_ID;

    ------------------------------------------------------------------
    -- Create Metadata Tables
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE
    '
    CREATE TABLE IF NOT EXISTS "' || P_TARGET_SCHEMA || '".LOAD_BATCH
    (
        LOAD_ID NUMBER,
        LOAD_START_TIME TIMESTAMP_NTZ,
        LOAD_END_TIME TIMESTAMP_NTZ
    )';

    EXECUTE IMMEDIATE
    '
    CREATE TABLE IF NOT EXISTS "' || P_TARGET_SCHEMA || '".FILE_LOAD_AUDIT
    (
        LOAD_ID NUMBER,
        TABLE_NAME VARCHAR,
        FILE_NAME VARCHAR,
        ROWS_LOADED NUMBER,
        LOAD_TIMESTAMP TIMESTAMP_NTZ
    )';

    ------------------------------------------------------------------
    -- Record Batch Start
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE
    '
    INSERT INTO "' || P_TARGET_SCHEMA || '".LOAD_BATCH
    (
        LOAD_ID,
        LOAD_START_TIME,
        LOAD_END_TIME
    )
    VALUES
    (
        ' || LOAD_ID || ',
        CURRENT_TIMESTAMP(),
        NULL
    )';

    ------------------------------------------------------------------
    -- List Files From Stage
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE 'LIST ' || P_STAGE_NAME;

    RS := (
        SELECT DISTINCT
            UPPER(SPLIT_PART("name",'/',2)) AS TABLE_NAME,
            SPLIT_PART("name",'/',2) AS FOLDER_NAME
        FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
    );

    ------------------------------------------------------------------
    -- Process Folder = One Table
    ------------------------------------------------------------------
    FOR ROW_RECORD IN RS DO

        TABLE_NAME := ROW_RECORD.TABLE_NAME;
        FOLDER_NAME := ROW_RECORD.FOLDER_NAME;

        FOLDER_PATH :=
            REPLACE(P_STAGE_NAME,'@','')
            || '/'
            || FOLDER_NAME
            || '/';

        --------------------------------------------------------------
        -- Check Table Exists
        --------------------------------------------------------------
        SELECT COUNT(*)
        INTO :TABLE_EXISTS
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = UPPER(:P_TARGET_SCHEMA)
          AND TABLE_NAME = UPPER(:TABLE_NAME);

        --------------------------------------------------------------
        -- Create Table If Needed
        --------------------------------------------------------------
        IF (TABLE_EXISTS = 0) THEN

            CREATE_TABLE_DDL :=
                'CREATE TABLE "' || P_TARGET_SCHEMA || '"."' ||
                TABLE_NAME || '" USING TEMPLATE (
                    SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                    FROM TABLE(
                        INFER_SCHEMA(
                            LOCATION => ''@' || FOLDER_PATH || ''',
                            FILE_FORMAT => ''' || P_FILE_FORMAT_NAME || '''
                        )
                    )
                )';

            EXECUTE IMMEDIATE CREATE_TABLE_DDL;

        END IF;

        --------------------------------------------------------------
        -- Enable Schema Evolution
        --------------------------------------------------------------
        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" SET ENABLE_SCHEMA_EVOLUTION = TRUE';

        --------------------------------------------------------------
        -- Audit Columns
        --------------------------------------------------------------
        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" ADD COLUMN IF NOT EXISTS CREATED_LOAD_ID NUMBER';

        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" ADD COLUMN IF NOT EXISTS CREATED_DATE_TIME TIMESTAMP_NTZ';

        --------------------------------------------------------------
        -- Folder Load
        --------------------------------------------------------------
        COPY_INTO_DDL :=
            'COPY INTO "' || P_TARGET_SCHEMA || '"."' || TABLE_NAME || '" ' ||
            'FROM ''@' || FOLDER_PATH || ''' ' ||
            'FILE_FORMAT=(FORMAT_NAME=''' || P_FILE_FORMAT_NAME || ''') ' ||
            'MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE ' ||
            'ON_ERROR=CONTINUE';

        EXECUTE IMMEDIATE COPY_INTO_DDL;

        --------------------------------------------------------------
        -- Stamp Newly Loaded Rows
        --------------------------------------------------------------
        EXECUTE IMMEDIATE
        'UPDATE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME || '" ' ||
        'SET CREATED_LOAD_ID = ' || LOAD_ID || ',
             CREATED_DATE_TIME = CURRENT_TIMESTAMP()
         WHERE CREATED_LOAD_ID IS NULL';

        PROCESSED_COUNT := PROCESSED_COUNT + 1;

    END FOR;

    ------------------------------------------------------------------
    -- Mark Batch End Time
    ------------------------------------------------------------------
    EXECUTE IMMEDIATE
    '
    UPDATE "' || P_TARGET_SCHEMA || '".LOAD_BATCH
    SET LOAD_END_TIME = CURRENT_TIMESTAMP()
    WHERE LOAD_ID = ' || LOAD_ID;

    RETURN
        'SUCCESS. LOAD_ID=' || LOAD_ID ||
        ', TABLES PROCESSED=' || PROCESSED_COUNT;

EXCEPTION
    WHEN OTHER THEN
        RETURN 'FAILED : ' || SQLERRM;

END;
$$;


---Call eg 
--CALL CREATE_TABLES_FROM_ALL_STAGE_FILES(
--    '@UPI_FRAUD_MONITORING_DB.TESTING.TESTING',
--'UPI_FRD_MONITORING_CSV_FORMAT',
--'TESTING'
--);
--