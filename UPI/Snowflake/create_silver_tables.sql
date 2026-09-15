create or replace procedure create_silver_tables(
    source_schema string,
    target_schema string
)
returns string
language javascript
as
$$
    var sourceSchema = arguments[0];   // first parameter
    var targetSchema = arguments[1];   // second parameter
    var result_msg = "";

    // Step 1: Get all tables in the source schema
    var get_tables = "select table_name,REPLACE(table_name,'V_','') as new_table_name " +
                     "from information_schema.tables " +
                     "where table_schema = '" + sourceSchema + "' " +
                     "and table_type = 'VIEW' and table_name not like 'V_RAW%'";

    var stmt_tables = snowflake.createStatement({sqlText: get_tables});
    var rs_tables = stmt_tables.execute();

    while (rs_tables.next()) {
        var table_name = rs_tables.getColumnValue("TABLE_NAME");
        var new_table_name = rs_tables.getColumnValue("NEW_TABLE_NAME");

        // Step 2: Get column metadata for each table
        var get_cols = "select column_name, data_type " +
                       "from information_schema.columns " +
                       "where table_schema = '" + sourceSchema + "' " +
                       "and table_name = '" + table_name + "' " +
                       "order by ordinal_position";

        var stmt_cols = snowflake.createStatement({sqlText: get_cols});
        var rs_cols = stmt_cols.execute();

        var col_defs = [];
        while (rs_cols.next()) {
            var col_name = rs_cols.getColumnValue("COLUMN_NAME");
            var data_type = rs_cols.getColumnValue("DATA_TYPE");
            col_defs.push(col_name + " " + data_type);
        }

        // Step 3: Add extra SCD2 columns
        
        col_defs.push("is_current boolean");
        col_defs.push("updated_load_id string");
        col_defs.push("updated_date_time timestamp");

        // Step 4: Build CREATE TABLE statement
        var sql_command = "create or replace table  " + targetSchema + ".sl_" + new_table_name  + " (" +
                          col_defs.join(",\n") + ")";

        // Step 5: Execute CREATE TABLE
        var create_stmt = snowflake.createStatement({sqlText: sql_command});
        create_stmt.execute();

        result_msg += "Created table: sl_" + targetSchema + "." + table_name + "\n";
    }

    return result_msg;
$$;