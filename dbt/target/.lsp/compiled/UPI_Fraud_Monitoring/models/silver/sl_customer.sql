
        merge into transform.sl_customer as tgt
        using (
            select
                customer_id,
                created_load_id,
                md5(coalesce(trim(CUSTOMER_NAME), '^') || '|' || coalesce(DOB::string, '^') || '|' || coalesce(trim(GENDER), '^') || '|' || coalesce(MOBILE_NUMBER::string, '^') || '|' || coalesce(trim(EMAIL_ID), '^') || '|' || coalesce(trim(CUSTOMER_SEGMENT), '^') || '|' || coalesce(trim(CUSTOMER_TYPE), '^') || '|' || coalesce(trim(KYC_STATUS), '^') || '|' || coalesce(trim(RISK_RATING), '^') || '|' || coalesce(CUSTOMER_SINCE::string, '^') || '|' || coalesce(trim(CUSTOMER_STATUS), '^') || '|' || coalesce(trim(SOURCE_FILE_NAME), '^') || '|' || coalesce(trim(HASH_DIFF), '^')) as hash_diff,
                current_timestamp() as CREATED_DATE_TIME,
            from transform.v_customer
        ) as src
        on tgt.customer_id = src.customer_id
        when matched and tgt.hash_diff <> src.hash_diff and tgt.is_current = true then
            update set tgt.is_current = false,
                       tgt.UPDATED_DATE_TIME = current_timestamp()
        when not matched then
            insert (
                customer_id,
                created_load_id,
                hash_diff,
                CREATED_DATE_TIME,
                UPDATED_DATE_TIME,
                is_current
            )
            values (
                src.customer_id,
                src.created_load_id,
                src.hash_diff,
                src.CREATED_DATE_TIME,
                null,
                true
            );
    