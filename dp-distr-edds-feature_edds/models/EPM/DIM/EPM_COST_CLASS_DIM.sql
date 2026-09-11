-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : COST_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_COST_CLASS_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_GL_DEPT_DIM.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_COST_CLASS_DIM',
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


WITH SQ_PS_PROJ_RES_TP_D00 AS
(
    SELECT
        SRC.RESOURCE_TYPE,
        SRC.EFFDT,
        SRC.EFF_STATUS,
        SRC.DESCR
    FROM {{ source('CRPDB01_EPMADM', 'PS_PROJ_RES_TP_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJ_RES_TP_D00 */ AS SRC
    WHERE SRC.SETID = 'AEP'
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        TRIM(SQ.RESOURCE_TYPE) AS RESOURCE_TYPE,
        SQ.EFFDT,
        TRIM(SQ.EFF_STATUS) AS EFF_STATUS,
        TRIM(SQ.DESCR) AS DESCR
    FROM SQ_PS_PROJ_RES_TP_D00 AS SQ
),
EXP_COST_CLS_DIM AS
(
    SELECT
        DQ.RESOURCE_TYPE AS COST_CLASS_STR,
        DQ.DESCR AS COST_CLASS_DESC,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    COST_CLASS_STR,
    COST_CLASS_DESC,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_COST_CLS_DIM
