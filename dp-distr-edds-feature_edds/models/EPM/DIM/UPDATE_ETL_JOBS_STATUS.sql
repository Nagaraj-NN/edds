-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_DIM_TABLES.sql
-- MAPPING NAME      : UPDATE_ETL_JOBS_STATUS
-- TARGET TABLE      : CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_DIM_TABLES_ASYS
-- MATERIALIZATION   : view
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_PROJECT_DIM.sql; the file name now matches the mapping UPDATE_ETL_JOBS_STATUS.
--           Model code unchanged.
-- NOTE    : disabled under the ci target in dbt_project.yml, because its
--           hook updates the shared PS_Z_ETL_JOBS control table.
-- ============================================================

{{ config(
    materialized='view',
    meta={" MAPPING_NAME ": "UPDATE_ETL_JOBS_STATUS"},
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_DIM_TABLES_ASYS'),
        "UPDATE {{ source('CRPDB01_EPMADM', 'PS_Z_ETL_JOBS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS */ AS TGT
        SET
        Z_RUN_PARM1 = TRIM(TGT.Z_RUN_PARM1),
        Z_RUN_PARM2 = TRIM(TGT.Z_RUN_PARM2),
        Z_RUN_PARM3 = TRIM(TGT.Z_RUN_PARM3),
        Z_RUN_PARM4 = TRIM(TGT.Z_RUN_PARM4),
        Z_RUN_PARM5 = TRIM(TGT.Z_RUN_PARM5),
        STATUS = 'C'
        WHERE TGT.JOB_ID = 'EDDS_DIM'"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_DIM_TABLES_ASYS')
    ]
) }}

SELECT 'This model executes the UPDATE_ETL_JOBS_STATUS update mapping for PS_Z_ETL_JOBS' AS Model_Description
