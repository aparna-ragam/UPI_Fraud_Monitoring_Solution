import os
import snowflake.connector

conn = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    password=os.environ["SNOWFLAKE_PASSWORD"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database=os.environ["SNOWFLAKE_DATABASE"],
    schema=os.environ["SNOWFLAKE_SCHEMA"],
    role=os.environ["SNOWFLAKE_ROLE"]
)

cur = conn.cursor()

cur.execute("""
SELECT LOAD_ID
FROM TAB_TEST.LOAD_BATCH
WHERE STATUS='COMPLETED'
  AND DBT_TRIGGERED='N'
ORDER BY LOAD_ID
LIMIT 1
""")

row = cur.fetchone()

if row is None:
    print("No new completed loads found")

    with open(os.environ["GITHUB_ENV"], "a") as f:
        f.write("RUN_DBT=N\n")

    conn.close()
    exit(0)

load_id = row[0]

print(f"Found load {load_id}")

cur.execute(f"""
UPDATE TAB_TEST.LOAD_BATCH
SET DBT_TRIGGERED='Y',
    DBT_TRIGGER_TIME=CURRENT_TIMESTAMP()
WHERE LOAD_ID={load_id}
""")

conn.commit()

with open(os.environ["GITHUB_ENV"], "a") as f:
    f.write("RUN_DBT=Y\n")

conn.close()