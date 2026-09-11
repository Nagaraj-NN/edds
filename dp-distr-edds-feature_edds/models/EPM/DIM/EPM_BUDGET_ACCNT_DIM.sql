-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : ACCOUNT_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_BUDGET_ACCNT_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was DWMS_SOURCE_STATUS.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_BUDGET_ACCNT_DIM',
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

WITH SQ_PS_GL_ACCOUNT_TBL AS
(
    SELECT
        SRC.ACCOUNT,
        SRC.EFFDT,
        SRC.EFF_STATUS,
        SRC.DESCR
    FROM {{ source('CRPDB01_EPMADM', 'PS_GL_ACCOUNT_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_GL_ACCOUNT_TBL */ AS SRC
    WHERE SRC.SETID = 'AEP'
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT
        RTRIM(SQ.ACCOUNT) AS ACCOUNT,
        SQ.EFFDT,
        RTRIM(SQ.EFF_STATUS) AS EFF_STATUS,
        RTRIM(SQ.DESCR) AS DESCR
    FROM SQ_PS_GL_ACCOUNT_TBL AS SQ
),
EXP_ACCNT_DIM AS
(
    SELECT
        DQ.ACCOUNT AS BUDGET_ACCNT_STR,
        DQ.DESCR AS BUDGET_ACCNT_DESC,
        DQ.EFFDT AS EFF_DATE,
        DQ.EFF_STATUS,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
)
SELECT
    BUDGET_ACCNT_STR,
    BUDGET_ACCNT_DESC,
    EFF_DATE,
    EFF_STATUS,
    LOAD_DATE
FROM EXP_ACCNT_DIM
