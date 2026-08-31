CREATE OR REPLACE PROCEDURE UPI_FRAUD_MONITORING_DB.STAGING.CREATE_TABLES_FROM_ALL_STAGE_FILES
(
    STAGE_NAME VARCHAR,
    FILE_FORMAT_NAME VARCHAR
)
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    list_query_id STRING;
    processed_count NUMBER DEFAULT 0;

    file_path STRING;
    table_name STRING;

    stage_file_path STRING;
    create_table_ddl STRING;
    copy_into_ddl STRING;

    load_id NUMBER;
    src_file_name STRING;

    rs RESULTSET;
BEGIN
    SELECT UPI_FRAUD_MONITORING_DB.STAGING.LOAD_ID_SEQ.NEXTVAL
    INTO :load_id;

    EXECUTE IMMEDIATE 'LIST ' || STAGE_NAME;

    list_query_id := LAST_QUERY_ID();

    rs := (
        SELECT
            "name",
            UPPER(
                REGEXP_REPLACE(
                    REGEXP_SUBSTR("name",'[^/]+$'),
                    '\\.[^.]+$',
                    ''
                )
            ) as column2
        FROM TABLE(RESULT_SCAN(:list_query_id))
    );

    FOR row_record IN rs DO

        file_path := row_record."name";
        table_name := row_record.COLUMN2;

        stage_file_path :=
            STAGE_NAME || '/'
            || REGEXP_SUBSTR(file_path,'[^/]+$');

        create_table_ddl :=
            'CREATE OR REPLACE TABLE "' || table_name || '" ' ||
            'USING TEMPLATE ( ' ||
            'SELECT ARRAY_AGG(OBJECT_CONSTRUCT(*)) ' ||
            'FROM TABLE( ' ||
            'INFER_SCHEMA( ' ||
            'LOCATION => ''' || stage_file_path || ''', ' ||
            'FILE_FORMAT => ''' || FILE_FORMAT_NAME || ''' ' ||
            ')' ||
            ')' ||
            ')';        

        EXECUTE IMMEDIATE create_table_ddl;

        EXECUTE IMMEDIATE  'ALTER TABLE "' || table_name || '"ADD COLUMN IF NOT EXISTS SOURCE_FILE_NAME VARCHAR(500)';
        EXECUTE IMMEDIATE  'ALTER TABLE "' || table_name || '"ADD COLUMN IF NOT EXISTS CREATED_LOAD_ID NUMBER';
        EXECUTE IMMEDIATE 'ALTER TABLE "' || table_name || '"ADD COLUMN IF NOT EXISTS CREATED_DATE_TIME TIMESTAMP';

        src_file_name := REGEXP_SUBSTR(file_path,'[^/]+$');

        copy_into_ddl :=
            'COPY INTO "' || table_name || '" ' ||
            'FROM ''' || stage_file_path || ''' ' ||
            'FILE_FORMAT=(FORMAT_NAME=''' || FILE_FORMAT_NAME || ''') ' ||
            'MATCH_BY_COLUMN_NAME=CASE_INSENSITIVE' ||
            ' ON_ERROR=CONTINUE';

        EXECUTE IMMEDIATE copy_into_ddl;

        EXECUTE IMMEDIATE 'UPDATE "' || table_name || '"SET SOURCE_FILE_NAME = ''' || src_file_name || ''',CREATED_LOAD_ID = ' || load_id ||                      ',CREATED_DATE_TIME = CURRENT_TIMESTAMP()
        WHERE CREATED_LOAD_ID IS NULL';

        processed_count := processed_count + 1;

    END FOR;

    RETURN 'Success: Processed ' || processed_count || ' file(s)';

EXCEPTION
    WHEN OTHER THEN
        RETURN SQLERRM;

END;
$$;