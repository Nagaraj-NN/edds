-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_DWMS_ACTUAL_DATA.sql
-- MAPPING NAME      : INS_DWMS_SOURCE_STATUS
-- TARGET TABLE      : DWMRP_DEV_SANDBOX.DWMR.DWMS_SOURCE_STATUS
-- AUTOSYS_JOB_NAME  : LOAD_DWMS_ACTUAL_DATA_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_BENEFIT_LOC_DIM.sql; the file name now matches the table this model builds.
-- CHANGED : added full_refresh=false, and the read of this model's own
--           table now runs only once that table exists (is_incremental).
--           The first build uses NULLs instead, as MAX() over no rows would.
-- ============================================================

{{ config(
    database='DWMRP_DEV_SANDBOX',
    schema='DWMR',
    alias='DWMS_SOURCE_STATUS',
    materialized='incremental',
    incremental_strategy='append',
    full_refresh=false,
    pre_hook=[
        log_model_start(this, 'LOAD_DWMS_ACTUAL_DATA_ASYS')
    ],
    post_hook=[
        log_model_end(this, 'LOAD_DWMS_ACTUAL_DATA_ASYS')
    ]
) }}


WITH SQ_DWMS_SOURCE_STATUS AS
(
{% if is_incremental() %}
    SELECT
        MAX(SRC.TS_RUN) AS TS_RUN,
        MAX(SRC.LOAD_DATE) AS LOAD_DATE
    FROM {{ this }} /* DWMRP_DEV_SANDBOX.DWMR.DWMS_SOURCE_STATUS */ AS SRC
{% else %}
    -- first build: the table does not exist yet, and MAX() over no rows is NULL
    SELECT
        CAST(NULL AS TIMESTAMP_NTZ) AS TS_RUN,
        CAST(NULL AS TIMESTAMP_NTZ) AS LOAD_DATE
{% endif %}
)
SELECT
    'EPM' AS SOURCE_NAME,
    SQ.TS_RUN,
    'Y' AS IND_SUCCESS,
    SQ.LOAD_DATE
FROM SQ_DWMS_SOURCE_STATUS AS SQ
