-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : DEPT_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_GL_DEPT_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_PROC_ACTIV_DIM.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_GL_DEPT_DIM',
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

WITH SQ_PS_DEPARTMENT_TBL AS
(
    SELECT
        D.SETID,
        D.DEPTID,
        D.EFFDT,
        D.EFF_STATUS,
        D.DESCR
    FROM {{ source('CRPDB01_EPMADM', 'PS_DEPARTMENT_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_DEPARTMENT_TBL */ AS D
    INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_GL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_BUS_UNIT_TBL_GL */ AS GL
        ON GL.BUSINESS_UNIT = D.SETID
    WHERE D.SETID NOT IN ('AEP', 'BUD')
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        RTRIM(SQ.SETID) AS SETID,
        RTRIM(SQ.DEPTID) AS DEPTID,
        SQ.EFFDT,
        RTRIM(SQ.EFF_STATUS) AS EFF_STATUS,
        RTRIM(SQ.DESCR) AS DESCR
    FROM SQ_PS_DEPARTMENT_TBL AS SQ
),
EXP_DEPT_DIM AS
(
    SELECT
        DQ.SETID AS GL_BUSINESS_UNIT,
        DQ.DEPTID AS GL_DEPT_STR,
        DQ.DESCR AS GL_DEPT_DESC,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    GL_BUSINESS_UNIT,
    GL_DEPT_STR,
    GL_DEPT_DESC,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_DEPT_DIM
