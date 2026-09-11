-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : PROJECT_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_PROJECT_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_PROJECT_WO_DIM.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_PROJECT_DIM',
    materialized='table',
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS'),
        "TRUNCATE TABLE IF EXISTS {{ this }}"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}

WITH SQ_PS_PROJECT_D00 AS
(
    SELECT
        SRC.BUSINESS_UNIT,
        SRC.PROJECT_ID,
        SRC.EFFDT,
        SRC.EFF_STATUS,
        SRC.DESCR,
        SRC.PROJECT_TYPE
    FROM {{ source('CRPDB01_EPMADM', 'PS_PROJECT_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJECT_D00 */ AS SRC
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        RTRIM(SQ.BUSINESS_UNIT) AS BUSINESS_UNIT,
        RTRIM(SQ.PROJECT_ID) AS PROJECT_ID,
        RTRIM(SQ.DESCR) AS DESCR,
        RTRIM(SQ.PROJECT_TYPE) AS PROJECT_TYPE,
        SQ.EFFDT,
        RTRIM(SQ.EFF_STATUS) AS EFF_STATUS
    FROM SQ_PS_PROJECT_D00 AS SQ
),
EXP_PROJECT_DIM AS
(
    SELECT
        DQ.BUSINESS_UNIT AS PROJ_BUSINESS_UNIT,
        DQ.PROJECT_ID AS PROJECT_STR,
        DQ.DESCR AS PROJECT_DESC,
        DQ.PROJECT_TYPE,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    PROJ_BUSINESS_UNIT,
    PROJECT_STR,
    PROJECT_DESC,
    PROJECT_TYPE,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_PROJECT_DIM
