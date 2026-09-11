-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : PROJ_ACTIVITY_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_PROJECT_WO_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was GL_BUS_UNIT_DIM.sql; the file name now matches the table this model builds.
--           Model code unchanged.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_PROJECT_WO_DIM',
    materialized='incremental',
    incremental_strategy='append',
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}

WITH SQ_PS_PROJ_ACT_D00 AS
(
    SELECT
        ACT.BUSINESS_UNIT,
        ACT.PROJECT_ID,
        ACT.ACTIVITY_ID,
        ACT.EFFDT,
        ACT.EFF_STATUS,
        ACT.DESCR,
        ACT.ACTIVITY_TYPE
    FROM {{ source('CRPDB01_EPMADM', 'PS_PROJ_ACT_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJ_ACT_D00 */ AS ACT
    INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_Z_ETL_JOBS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS */ AS JOB
        ON JOB.JOB_ID = 'EDDS_DIM'
    WHERE ACT.DTTM_STAMP > TO_TIMESTAMP_NTZ(JOB.Z_RUN_PARM1, 'YYYY-MM-DD-HH24.MI.SS')
      AND ACT.DTTM_STAMP <= TO_TIMESTAMP_NTZ(JOB.Z_RUN_PARM2, 'YYYY-MM-DD-HH24.MI.SS')
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        RTRIM(SQ.BUSINESS_UNIT) AS BUSINESS_UNIT,
        RTRIM(SQ.PROJECT_ID) AS PROJECT_ID,
        RTRIM(SQ.ACTIVITY_ID) AS ACTIVITY_ID,
        SQ.EFFDT,
        RTRIM(SQ.EFF_STATUS) AS EFF_STATUS,
        RTRIM(SQ.DESCR) AS DESCR,
        RTRIM(SQ.ACTIVITY_TYPE) AS ACTIVITY_TYPE
    FROM SQ_PS_PROJ_ACT_D00 AS SQ
),
EXP_PROJ_ACT_DIM AS
(
    SELECT
        DQ.BUSINESS_UNIT AS PROJ_BUSINESS_UNIT,
        DQ.PROJECT_ID AS PROJECT_STR,
        DQ.ACTIVITY_ID AS WORK_ORDER_NBR,
        DQ.DESCR AS WORK_ORDER_DESC,
        DQ.ACTIVITY_TYPE AS WORK_ORDER_TYPE,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    PROJ_BUSINESS_UNIT,
    PROJECT_STR,
    WORK_ORDER_NBR,
    WORK_ORDER_DESC,
    WORK_ORDER_TYPE,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_PROJ_ACT_DIM
