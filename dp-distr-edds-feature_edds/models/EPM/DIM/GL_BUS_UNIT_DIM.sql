-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : GL_BUS_UNIT_DIM
-- TARGET TABLE      : EDDSP.EPM.EPM_BUSINESS_UNIT_DIM
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : incremental
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was UPDATE_ETL_JOBS_STATUS_DWMS.sql; the file name now matches the mapping GL_BUS_UNIT_DIM.
--           Model code unchanged.
-- ============================================================

{{ config(
    materialized='view',
    meta={"session_name": "s_m_upd_edw_davox_tran_wv90aft606_concerto"},
    pre_hook=[
        log_model_start(this, 'EPM_BUSINESS_UNIT_DIM'),
        " MERGE INTO {{ ref('EPM_BUSINESS_UNIT_DIM') }} AS TGT
USING
(
    WITH SQ_PS_BUS_UNIT_TBL_GL AS
    (
        SELECT
            GL.BUSINESS_UNIT,
            FS.DESCR
        FROM {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_GL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_BUS_UNIT_TBL_GL */ AS GL
        INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_BUS_UNIT_TBL_FS */ AS FS
            ON FS.BUSINESS_UNIT = GL.BUSINESS_UNIT
    ),
    EXP_DATAQUALITYSTANDARDS1 AS
    (
        SELECT
            RTRIM(SQ.BUSINESS_UNIT) AS BUSINESS_UNIT,
            TRIM(SQ.DESCR) AS DESCR
        FROM SQ_PS_BUS_UNIT_TBL_GL AS SQ
    ),
    EXP_GL_BU_DIM AS
    (
        SELECT
            DQ.BUSINESS_UNIT AS BUSINESS_UNIT,
            DQ.DESCR AS BUSINESS_UNIT_DESC,
            'GL' AS OWNER,
            CURRENT_TIMESTAMP() AS LOAD_DATE
        FROM EXP_DATAQUALITYSTANDARDS1 AS DQ
    )
    SELECT
        BUSINESS_UNIT,
        BUSINESS_UNIT_DESC,
        OWNER,
        LOAD_DATE
    FROM EXP_GL_BU_DIM
) AS SRC
ON TGT.BUSINESS_UNIT = SRC.BUSINESS_UNIT
AND TGT.OWNER = SRC.OWNER
WHEN MATCHED THEN UPDATE SET
    TGT.BUSINESS_UNIT_DESC = SRC.BUSINESS_UNIT_DESC,
    TGT.LOAD_DATE = SRC.LOAD_DATE
WHEN NOT MATCHED THEN INSERT
(
    BUSINESS_UNIT,
    BUSINESS_UNIT_DESC,
    OWNER,
    LOAD_DATE
)
VALUES
(
    SRC.BUSINESS_UNIT,
    SRC.BUSINESS_UNIT_DESC,
    SRC.OWNER,
    SRC.LOAD_DATE
); "
],
    post_hook=[
        log_model_end(this, 'EPM_BUSINESS_UNIT_DIM')
    ]
) }}

SELECT  'This model is  inserting and updating data into EPM_BUSINESS_UNIT_DIM ' AS Model_Description
