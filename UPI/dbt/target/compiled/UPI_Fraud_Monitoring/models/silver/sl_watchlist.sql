


with source as (
select
    watchlist_id,
    entity_type,
    entity_id,
    entity_name,
    risk_level,
    created_load_id,
md5(
        coalesce(watchlist_id,'^') || '|' ||
        coalesce(entity_type,'^') || '|' ||
	coalesce(entity_id,'^') || '|' ||
	coalesce(entity_name,'^') || '|' ||
        coalesce(risk_level,'^')
    ) as hash_diff
from  UPI_FRAUD_MONITORING_DB.TRANSFORM.v_watchlist
)

select
    watchlist_id,
    entity_type,
    entity_id,
    entity_name,
    risk_level,
    hash_diff,
    created_load_id,
    current_timestamp() as created_date_time,
    null as updated_date_time,
    true as is_current
    from source