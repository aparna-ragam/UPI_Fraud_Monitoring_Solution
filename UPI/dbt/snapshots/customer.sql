{% snapshot sl_customer %}

{{
    config(
        target_schema='transform',
        unique_key='customer_id',
        strategy='check',
        check_cols = 'all',
        snapshot_meta_column_names={
        "dbt_valid_from": "created_date_time",
        "dbt_valid_to": "updated_date_time",
        "dbt_scd_id": "scd_id",
        "dbt_is_current": "is_current"
        }
    )
}}

select
    customer_id,
    customer_name,
    customer_segment,
    kyc_status,
    risk_rating,
    customer_status,
    customer_since,
    customer_type,
    created_load_id
from {{ ref('v_customer') }}

{% endsnapshot %}