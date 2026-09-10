CREATE OR REPLACE PROCEDURE UPI_DATA_INGEST_SP
(
    P_STAGE_NAME VARCHAR,
    P_FILE_FORMAT_NAME VARCHAR,
    P_TARGET_SCHEMA VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE

    LOAD_ID NUMBER;
    PROCESSED_COUNT NUMBER DEFAULT 0;
    TABLE_EXISTS NUMBER;

    TABLE_NAME STRING;
    FOLDER_NAME STRING;
    FOLDER_PATH STRING;

    CREATE_TABLE_DDL STRING;
    COPY_INTO_DDL STRING;

    RS RESULTSET;
    FILE_NAME STRING;
    

BEGIN

    ------------------------------------------------------------
    -- Generate Load ID
    ------------------------------------------------------------
    SELECT UPI_FRAUD_MONITORING_DB.STAGING.LOAD_ID_SEQ.NEXTVAL
    INTO :LOAD_ID;

    ------------------------------------------------------------
    -- Audit Tables
    ------------------------------------------------------------
    EXECUTE IMMEDIATE
    '
    CREATE TABLE IF NOT EXISTS "' || P_TARGET_SCHEMA || '".LOAD_BATCH
    (
        LOAD_ID NUMBER,
        LOAD_START_TIME TIMESTAMP_NTZ,
        LOAD_END_TIME TIMESTAMP_NTZ,
        STATUS STRING,
        DBT_TRIGGERED STRING ,
        DBT_TRIGGER_TIME TIMESTAMP_NTZ
    )';

    EXECUTE IMMEDIATE
    '
    CREATE TABLE IF NOT EXISTS "' || P_TARGET_SCHEMA || '".FILE_LOAD_AUDIT
    (
        LOAD_ID NUMBER,
        TABLE_NAME VARCHAR,
        FILE_NAME VARCHAR,
        LOAD_TIMESTAMP TIMESTAMP_NTZ
    )';

    ------------------------------------------------------------
    -- Batch Start
    ------------------------------------------------------------
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

    ------------------------------------------------------------
    -- Read folders from stream
    ------------------------------------------------------------
    RS :=
    (
        SELECT DISTINCT
            UPPER(SPLIT_PART(FILE_PATH,'/',2)) AS TABLE_NAME,
            SPLIT_PART(FILE_PATH,'/',2) AS FOLDER_NAME,
            FILE_NAME
        FROM STAGING.UPI_FILE_METADATA_STREAM
        WHERE METADATA$ACTION = 'INSERT'
    );

    ------------------------------------------------------------
    -- Process each folder
    ------------------------------------------------------------
    FOR REC IN RS DO

        TABLE_NAME := REC.TABLE_NAME;
        FOLDER_NAME := REC.FOLDER_NAME;
        FILE_NAME := REC.FILE_NAME;

        FOLDER_PATH :=
            P_STAGE_NAME || '/' || FOLDER_NAME;

        --------------------------------------------------------
        -- Check if table exists
        --------------------------------------------------------
        SELECT COUNT(*)
        INTO :TABLE_EXISTS
        FROM UPI_FRAUD_MONITORING_DB.INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = UPPER(:P_TARGET_SCHEMA)
          AND TABLE_NAME   = UPPER(:TABLE_NAME);

        --------------------------------------------------------
        -- Create table using schema inference
        --------------------------------------------------------
        IF (TABLE_EXISTS = 0) THEN

            CREATE_TABLE_DDL :=
            'CREATE TABLE "' || P_TARGET_SCHEMA || '"."' ||
            TABLE_NAME || '"
            USING TEMPLATE
            (
                SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*))
                FROM TABLE
                (
                    INFER_SCHEMA
                    (
                        LOCATION => ''' || FOLDER_PATH || ''',
                        FILE_FORMAT => ''' || P_FILE_FORMAT_NAME || ''',
                        IGNORE_CASE => TRUE
                    )
                )
            )';

            EXECUTE IMMEDIATE CREATE_TABLE_DDL;

        END IF;

        --------------------------------------------------------
        -- Schema evolution
        --------------------------------------------------------
        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" SET ENABLE_SCHEMA_EVOLUTION = TRUE';

        --------------------------------------------------------
        -- Audit columns
        --------------------------------------------------------
        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" ADD COLUMN IF NOT EXISTS CREATED_LOAD_ID NUMBER';

        EXECUTE IMMEDIATE
        'ALTER TABLE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME ||
        '" ADD COLUMN IF NOT EXISTS CREATED_DATE_TIME TIMESTAMP_NTZ';

        --------------------------------------------------------
        -- Load Data
        --------------------------------------------------------
        COPY_INTO_DDL :=
        'COPY INTO "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME || '"
        FROM ' || FOLDER_PATH || '
        FILE_FORMAT = (
            FORMAT_NAME = ''' || P_FILE_FORMAT_NAME || '''
        )
        MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
        ON_ERROR = CONTINUE';

        EXECUTE IMMEDIATE COPY_INTO_DDL;

        --------------------------------------------------------
        -- Audit Stamp
        --------------------------------------------------------
        EXECUTE IMMEDIATE
        'UPDATE "' || P_TARGET_SCHEMA || '"."' ||
        TABLE_NAME || '"
        SET CREATED_LOAD_ID = ' || LOAD_ID || ',
            CREATED_DATE_TIME = CURRENT_TIMESTAMP()
        WHERE CREATED_LOAD_ID IS NULL';

        --------------------------------------------------------
        -- Audit Log
        --------------------------------------------------------
        EXECUTE IMMEDIATE
        '
        INSERT INTO "' || P_TARGET_SCHEMA || '".FILE_LOAD_AUDIT
        (
            LOAD_ID,
            TABLE_NAME,
            FILE_NAME,
            LOAD_TIMESTAMP
        )
        VALUES
        (
            ' || LOAD_ID || ',
            ''' || TABLE_NAME || ''',
            ''' || FILE_NAME || ''',
            CURRENT_TIMESTAMP()
        )';

        PROCESSED_COUNT := PROCESSED_COUNT + 1;

    END FOR;

    ------------------------------------------------------------
    -- Batch End
    ------------------------------------------------------------
    
    EXECUTE IMMEDIATE
    'UPDATE "' || P_TARGET_SCHEMA || '".LOAD_BATCH
     SET LOAD_END_TIME = CURRENT_TIMESTAMP(),
     STATUS = ''COMPLETED''
    WHERE LOAD_ID = ' || LOAD_ID;

    RETURN
    'SUCCESS | LOAD_ID=' || LOAD_ID ||
    ' | TABLES_PROCESSED=' || PROCESSED_COUNT;

EXCEPTION

    WHEN OTHER THEN

        RETURN
        'FAILED | LOAD_ID=' || LOAD_ID ||
        ' | ERROR=' || SQLERRM;

END;
$$;