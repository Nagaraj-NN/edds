-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : ACTIVITY_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_PROC_ACTIV_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was UPDATE_ETL_JOBS_PARMS.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_PROC_ACTIV_DIM',
    materialized='incremental',
    incremental_strategy='append',
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS'),
        "TRUNCATE TABLE IF EXISTS {{ this }}"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}


WITH SQ_PS_PROJ_CATG_D00 AS
(
    SELECT
        SRC.RESOURCE_CATEGORY,
        SRC.EFFDT,
        SRC.EFF_STATUS,
        SRC.DESCR
    FROM {{ source('CRPDB01_EPMADM', 'PS_PROJ_CATG_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJ_CATG_D00 */ AS SRC
    WHERE SRC.SETID = 'AEP'
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        RTRIM(SQ.RESOURCE_CATEGORY) AS RESOURCE_CATEGORY,
        SQ.EFFDT,
        RTRIM(SQ.EFF_STATUS) AS EFF_STATUS,
        RTRIM(SQ.DESCR) AS DESCR
    FROM SQ_PS_PROJ_CATG_D00 AS SQ
),
EXP_ABMS_ACT_DIM AS
(
    SELECT
        DQ.RESOURCE_CATEGORY AS PROC_ACTIV_STR,
        DQ.DESCR AS PROC_ACTIV_DESC,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    PROC_ACTIV_STR,
    PROC_ACTIV_DESC,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_ABMS_ACT_DIM
