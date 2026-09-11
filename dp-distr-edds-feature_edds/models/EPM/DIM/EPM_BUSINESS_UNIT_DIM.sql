-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : PROJ_BUS_UNIT_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_BUSINESS_UNIT_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : incremental
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_BUDGET_ACCNT_DIM.sql; the file name now matches the table this model builds.
--           Model code unchanged.
-- ============================================================

{{ config(
    database='EDDSP',
    schema='EPM',
    alias='EPM_BUSINESS_UNIT_DIM',
    materialized='incremental',
    unique_key=['BUSINESS_UNIT', 'OWNER'],
    incremental_strategy='merge',
    full_refresh=false,
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}


WITH SQ_PS_BUS_UNIT_SRC_PF AS
    (
        SELECT
            PF.BUSINESS_UNIT,
            PF.PS_OWNER,
            FS.DESCR
        FROM {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_SRC_PF') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_BUS_UNIT_SRC_PF */ AS PF
        INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_BUS_UNIT_TBL_FS */ AS FS
            ON PF.BUSINESS_UNIT = FS.BUSINESS_UNIT
        WHERE PF.PS_OWNER = 'PC'
    ),
    EXP_DATAQUALITYSTANDARDS1 AS
    (
        SELECT
            RTRIM(SQ.BUSINESS_UNIT) AS BUSINESS_UNIT,
            RTRIM(SQ.DESCR) AS DESCR,
            RTRIM(SQ.PS_OWNER) AS PS_OWNER
        FROM SQ_PS_BUS_UNIT_SRC_PF AS SQ
    ),
    EXP_PROJ_BU_DIM AS
    (
        SELECT
            DQ.BUSINESS_UNIT AS BUSINESS_UNIT,
            DQ.DESCR AS BUSINESS_UNIT_DESC,
            DQ.PS_OWNER AS OWNER,
            CURRENT_TIMESTAMP() AS LOAD_DATE
        FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
    )
    SELECT
        BUSINESS_UNIT,
        BUSINESS_UNIT_DESC,
        OWNER,
        LOAD_DATE
    FROM EXP_PROJ_BU_DIM
