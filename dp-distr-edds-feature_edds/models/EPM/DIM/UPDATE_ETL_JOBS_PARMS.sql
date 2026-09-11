-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : UPDATE_ETL_JOBS_PARMS
-- TARGET TABLE      : CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : view
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was UPDATE_ETL_JOBS_PARMS_DWMS.sql; the file name now matches the mapping UPDATE_ETL_JOBS_PARMS.
--           Model code unchanged.
-- NOTE    : disabled under the ci target in dbt_project.yml, because its
--           hook updates the shared PS_Z_ETL_JOBS control table.
-- ============================================================

{{ config(
    materialized='view',
    meta={"MAPPING_NAME": "UPDATE_ETL_JOBS_PARMS"},
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS'),
        "UPDATE {{ source('CRPDB01_EPMADM', 'PS_Z_ETL_JOBS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS */ AS TGT
        SET
        Z_RUN_PARM1 = CASE
                WHEN RTRIM(TGT.STATUS) = 'C' THEN RTRIM(TGT.Z_RUN_PARM2)
                    ELSE RTRIM(TGT.Z_RUN_PARM1)
                END,
        Z_RUN_PARM2 = CASE
                WHEN RTRIM(TGT.STATUS) = 'C' THEN TO_CHAR(CURRENT_TIMESTAMP(), 'YYYY-MM-DD-HH24.MI.SS')
                        ELSE RTRIM(TGT.Z_RUN_PARM2)
                END,
        Z_RUN_PARM3 = RTRIM(TGT.Z_RUN_PARM3),
        Z_RUN_PARM4 = RTRIM(TGT.Z_RUN_PARM4),
        Z_RUN_PARM5 = RTRIM(TGT.Z_RUN_PARM5),
        STATUS = 'R'
    WHERE TGT.JOB_ID = 'EDDS_DIM'"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}

SELECT 'This model executes the UPDATE_ETL_JOBS_PARMS update mapping for PS_Z_ETL_JOBS' AS Model_Description
