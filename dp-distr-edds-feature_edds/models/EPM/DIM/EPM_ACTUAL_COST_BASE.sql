-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_DWMS_ACTUAL_DATA.sql
-- MAPPING NAME      : LOAD_DWMS_ACTUAL_COST
-- TARGET TABLE      : DWMRP_DEV_SANDBOX.EPM.EPM_ACTUAL_COST_BASE
-- AUTOSYS_JOB_NAME  : LOAD_DWMS_ACTUAL_DATA_ASYS
-- MATERIALIZATION   : incremental
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_BUSINESS_UNIT_DIM.sql; the file name now matches the table this model builds.
--           Model code unchanged.
-- ============================================================

{{ config(
    database='DWMRP_DEV_SANDBOX',
    schema='EPM',
    alias='EPM_ACTUAL_COST_BASE',
    materialized='incremental',
    unique_key=['RESOURCE_ID', 'PROJECT_STR', 'PROJ_BUSINESS_UNIT', 'WORK_ORDER_NBR'],
    incremental_strategy='merge',
    full_refresh=false,
    pre_hook=[
        log_model_start(this, 'LOAD_DWMS_ACTUAL_DATA_ASYS')
    ],
    post_hook=[
        log_model_end(this, 'LOAD_DWMS_ACTUAL_DATA_ASYS')
    ]
) }}

WITH SQ_PS_PROJ_RES_ACT_VW AS
    (
        SELECT
            SRC.BUSINESS_UNIT,
            SRC.PROJECT_ID,
            SRC.ACTIVITY_ID,
            SRC.RESOURCE_ID,
            SRC.PF_TRANS_DT,
            SRC.BUSINESS_UNIT_GL,
            SRC.ACCOUNT,
            SRC.DEPTID,
            SRC.RESOURCE_TYPE,
            SRC.RESOURCE_CATEGORY,
            SRC.ACCOUNTING_DT,
            SRC.SYSTEM_SOURCE,
            SRC.EMPLID,
            SRC.BUSINESS_UNIT_AP,
            SRC.VENDOR_ID,
            SRC.VOUCHER_ID,
            SRC.RESOURCE_QUANTITY,
            SRC.RESOURCE_AMOUNT,
            SRC.ACCOUNTING_PERIOD,
            SRC.FISCAL_YEAR,
            SRC.Z_UPDATE_FLAG
        FROM {{ source('CRPDB01_BOEPMMRT', 'PS_PROJ_RES_ACT_VW') }} /* CRPDB01_DEV_SANDBOX.BOEPMMRT.PS_PROJ_RES_ACT_VW */ AS SRC
        INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_Z_ETL_JOBS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS */ AS JOB
            ON NULLIF(TRIM(JOB.JOB_ID), '') = 'DWMS'
        WHERE SRC.DTTM_STAMP >
              TO_TIMESTAMP_NTZ(
                  JOB.Z_RUN_PARM1,
                  'YYYY-MM-DD-HH24.MI.SS'
              )
          AND SRC.DTTM_STAMP <=
              TO_TIMESTAMP_NTZ(
                  JOB.Z_RUN_PARM2,
                  'YYYY-MM-DD-HH24.MI.SS'
              )
          AND SRC.ANALYSIS_TYPE IN
          (
              SELECT
                  ANG.ANALYSIS_TYPE
              FROM {{ source('CRPDB01_EPMADM', 'PS_PROJ_ANGRP_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJ_ANGRP_D00 */ AS ANG
              WHERE ANG.ANALYSIS_GROUP IN
              (
                  'RPACT',
                  'RALAB',
                  'RASCB',
                  'RAICB',
                  'RASTR',
                  'RARDD',
                  'RABLD',
                  'RAJNT',
                  'RACMF',
                  'RAMSC'
              )
          )
          AND SRC.ACCOUNTING_PERIOD BETWEEN 1 AND 12
          AND SRC.FISCAL_YEAR >= 2006
          AND SRC.BUSINESS_UNIT <> ' '
          AND SRC.PROJECT_ID <> ' '
          AND SRC.ACTIVITY_ID <> ' '
          AND SRC.RESOURCE_ID <> ' '
          AND SRC.DEPTID IN
          (
              SELECT DISTINCT
                  DPT.Z_DESCENDANT
              FROM {{ source('CRPDB01_EPMADM', 'PS_Z_DEPT_NOD') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_DEPT_NOD */ AS DPT
              INNER JOIN {{ source('CRPDB01_EPMADM', 'PS_Z_ETL_JOBS') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_ETL_JOBS */ AS DJOB
                  ON NULLIF(TRIM(DJOB.JOB_ID), '') = 'DWMS'
              WHERE DPT.Z_LEVEL_NUM = 99
                AND
                (
                    DPT.Z_START_VALUE = DJOB.Z_RUN_PARM3
                    OR DPT.Z_START_VALUE = DJOB.Z_RUN_PARM4
                    OR DPT.Z_START_VALUE = DJOB.Z_RUN_PARM5
                    OR DPT.Z_START_VALUE = '99990'
                )
          )
    ),
    EXP_DATA_QUALITY_STANDARDS1 AS
    (
        SELECT
            NULLIF(TRIM(BUSINESS_UNIT), '') AS BUSINESS_UNIT,
            NULLIF(TRIM(PROJECT_ID), '') AS PROJECT_ID,
            NULLIF(TRIM(ACTIVITY_ID), '') AS ACTIVITY_ID,
            NULLIF(TRIM(RESOURCE_ID), '') AS RESOURCE_ID,
            PF_TRANS_DT,
            NULLIF(TRIM(BUSINESS_UNIT_GL), '') AS BUSINESS_UNIT_GL,
            NULLIF(TRIM(ACCOUNT), '') AS ACCOUNT,
            NULLIF(TRIM(DEPTID), '') AS DEPTID,
            NULLIF(TRIM(RESOURCE_TYPE), '') AS RESOURCE_TYPE,
            NULLIF(TRIM(RESOURCE_CATEGORY), '') AS RESOURCE_CATEGORY,
            ACCOUNTING_DT,
            NULLIF(TRIM(SYSTEM_SOURCE), '') AS SYSTEM_SOURCE,
            NULLIF(TRIM(EMPLID), '') AS EMPLID,
            NULLIF(TRIM(BUSINESS_UNIT_AP), '') AS BUSINESS_UNIT_AP,
            NULLIF(TRIM(VENDOR_ID), '') AS VENDOR_ID,
            NULLIF(TRIM(VOUCHER_ID), '') AS VOUCHER_ID,
            RESOURCE_QUANTITY,
            RESOURCE_AMOUNT,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            NULLIF(TRIM(Z_UPDATE_FLAG), '') AS Z_UPDATE_FLAG
        FROM SQ_PS_PROJ_RES_ACT_VW
    ),
    EXP_DWMS_ACTUAL_COST AS
    (
        SELECT
            RESOURCE_ID,
            PROJECT_ID AS PROJECT_STR,
            BUSINESS_UNIT AS PROJ_BUSINESS_UNIT,
            ACTIVITY_ID AS WORK_ORDER_NBR,
            PF_TRANS_DT,
            ACCOUNTING_DT,
            BUSINESS_UNIT_GL AS GL_BUSINESS_UNIT,
            ACCOUNT AS BUDGET_ACCNT_STR,
            DEPTID AS GL_DEPT_STR,
            RESOURCE_TYPE AS COST_CLASS_STR,
            RESOURCE_CATEGORY AS PROC_ACTIV_STR,
            SYSTEM_SOURCE AS ORIGIN_SYSTEM,
            EMPLID,
            BUSINESS_UNIT_AP,
            VENDOR_ID,
            VOUCHER_ID,
            RESOURCE_QUANTITY AS ACTUAL_HOURS,
            RESOURCE_AMOUNT AS ACTUAL_COST,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            Z_UPDATE_FLAG
        FROM EXP_DATA_QUALITY_STANDARDS1
    ),
    FLTR_TIME_AND_LABOR AS
    (
        SELECT
            RESOURCE_ID,
            PROJECT_STR,
            PROJ_BUSINESS_UNIT,
            WORK_ORDER_NBR,
            PF_TRANS_DT,
            ACCOUNTING_DT,
            GL_BUSINESS_UNIT,
            BUDGET_ACCNT_STR,
            GL_DEPT_STR,
            COST_CLASS_STR,
            PROC_ACTIV_STR,
            ORIGIN_SYSTEM,
            EMPLID,
            BUSINESS_UNIT_AP,
            VENDOR_ID,
            VOUCHER_ID,
            ACTUAL_HOURS,
            ACTUAL_COST,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            Z_UPDATE_FLAG
        FROM EXP_DWMS_ACTUAL_COST
        WHERE ORIGIN_SYSTEM IN ('TLB', 'CUA')
    ),
    EXP_TIME_AND_LABOR AS
    (
        SELECT
            RESOURCE_ID,
            PROJECT_STR,
            PROJ_BUSINESS_UNIT,
            WORK_ORDER_NBR,
            CAST(NULL AS VARCHAR) AS INVOICE_NBR,
            EMPLID,
            CAST(NULL AS TIMESTAMP_NTZ) AS INVOICE_DATE,
            PF_TRANS_DT AS TRANSACTION_DATE,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            VENDOR_ID,
            ORIGIN_SYSTEM,
            GL_BUSINESS_UNIT,
            GL_DEPT_STR,
            PROC_ACTIV_STR,
            BUDGET_ACCNT_STR,
            COST_CLASS_STR,
            ACTUAL_HOURS,
            ACTUAL_COST,
            CURRENT_TIMESTAMP() AS LOAD_DATE,
            CURRENT_TIMESTAMP() AS LAST_UPDATE_DATE,
            Z_UPDATE_FLAG
        FROM FLTR_TIME_AND_LABOR
    ),
    FLTR_OUTSIDE_SERVICES AS
    (
        SELECT
            RESOURCE_ID,
            PROJECT_STR,
            PROJ_BUSINESS_UNIT,
            WORK_ORDER_NBR,
            PF_TRANS_DT,
            ACCOUNTING_DT,
            GL_BUSINESS_UNIT,
            BUDGET_ACCNT_STR,
            GL_DEPT_STR,
            COST_CLASS_STR,
            PROC_ACTIV_STR,
            ORIGIN_SYSTEM,
            EMPLID,
            BUSINESS_UNIT_AP,
            VENDOR_ID,
            VOUCHER_ID,
            ACTUAL_HOURS,
            ACTUAL_COST,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            Z_UPDATE_FLAG
        FROM EXP_DWMS_ACTUAL_COST
        WHERE ORIGIN_SYSTEM <> 'TLB'
          AND ORIGIN_SYSTEM <> 'CUA'
    ),
    LKP_VOUCHER_ID AS
    (
        SELECT
            NULLIF(TRIM(VCH.INVOICE_ID), '') AS INVOICE_ID,
            VCH.INVOICE_DT,
            NULLIF(TRIM(VCH.ORIGIN), '') AS ORIGIN,
            NULLIF(TRIM(VCH.BUSINESS_UNIT), '') AS BUSINESS_UNIT,
            NULLIF(TRIM(VCH.VOUCHER_ID), '') AS VOUCHER_ID
        FROM {{ source('CRPDB01_EPMADM', 'PS_VOUCHER_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_VOUCHER_D00 */ AS VCH
        WHERE VCH.BUSINESS_UNIT <> ' '
          AND VCH.VOUCHER_ID <> ' '
        QUALIFY ROW_NUMBER() OVER
        (
            PARTITION BY
                UPPER(NULLIF(TRIM(VCH.BUSINESS_UNIT), '')),
                UPPER(NULLIF(TRIM(VCH.VOUCHER_ID), ''))
            ORDER BY
                VCH.BUSINESS_UNIT,
                VCH.VOUCHER_ID,
                VCH.INVOICE_ID,
                VCH.INVOICE_DT,
                VCH.ORIGIN
        ) = 1
    ),
    EXP_OUTSIDE_SERVICES AS
    (
        SELECT
            OUTS.RESOURCE_ID,
            OUTS.PROJECT_STR,
            OUTS.PROJ_BUSINESS_UNIT,
            OUTS.WORK_ORDER_NBR,
            LKP.INVOICE_ID AS INVOICE_NBR,
            OUTS.EMPLID,
            LKP.INVOICE_DT AS INVOICE_DATE,
            OUTS.ACCOUNTING_DT AS TRANSACTION_DATE,
            OUTS.ACCOUNTING_PERIOD,
            OUTS.FISCAL_YEAR,
            OUTS.VENDOR_ID,
            COALESCE(
                LKP.ORIGIN,
                OUTS.ORIGIN_SYSTEM
            ) AS ORIGIN_SYSTEM,
            OUTS.GL_BUSINESS_UNIT,
            OUTS.GL_DEPT_STR,
            OUTS.PROC_ACTIV_STR,
            OUTS.BUDGET_ACCNT_STR,
            OUTS.COST_CLASS_STR,
            CAST(0 AS NUMBER(14, 2)) AS ACTUAL_HOURS,
            OUTS.ACTUAL_COST,
            CURRENT_TIMESTAMP() AS LOAD_DATE,
            CURRENT_TIMESTAMP() AS LAST_UPDATE_DATE,
            OUTS.Z_UPDATE_FLAG
        FROM FLTR_OUTSIDE_SERVICES AS OUTS
        LEFT JOIN LKP_VOUCHER_ID AS LKP
            ON UPPER(LKP.BUSINESS_UNIT) =
               UPPER(OUTS.BUSINESS_UNIT_AP)
           AND UPPER(LKP.VOUCHER_ID) =
               UPPER(OUTS.VOUCHER_ID)
    ),
    FINAL_FLOW AS
    (
        SELECT
            RESOURCE_ID,
            PROJECT_STR,
            PROJ_BUSINESS_UNIT,
            WORK_ORDER_NBR,
            INVOICE_NBR,
            EMPLID,
            INVOICE_DATE,
            TRANSACTION_DATE,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            VENDOR_ID,
            ORIGIN_SYSTEM,
            GL_BUSINESS_UNIT,
            GL_DEPT_STR,
            PROC_ACTIV_STR,
            BUDGET_ACCNT_STR,
            COST_CLASS_STR,
            ACTUAL_HOURS,
            ACTUAL_COST,
            LOAD_DATE,
            LAST_UPDATE_DATE,
            Z_UPDATE_FLAG
        FROM EXP_TIME_AND_LABOR

        UNION ALL

        SELECT
            RESOURCE_ID,
            PROJECT_STR,
            PROJ_BUSINESS_UNIT,
            WORK_ORDER_NBR,
            INVOICE_NBR,
            EMPLID,
            INVOICE_DATE,
            TRANSACTION_DATE,
            ACCOUNTING_PERIOD,
            FISCAL_YEAR,
            VENDOR_ID,
            ORIGIN_SYSTEM,
            GL_BUSINESS_UNIT,
            GL_DEPT_STR,
            PROC_ACTIV_STR,
            BUDGET_ACCNT_STR,
            COST_CLASS_STR,
            ACTUAL_HOURS,
            ACTUAL_COST,
            LOAD_DATE,
            LAST_UPDATE_DATE,
            Z_UPDATE_FLAG
        FROM EXP_OUTSIDE_SERVICES
    )
    SELECT
        RESOURCE_ID,
        PROJECT_STR,
        PROJ_BUSINESS_UNIT,
        WORK_ORDER_NBR,
        INVOICE_NBR,
        EMPLID,
        INVOICE_DATE,
        TRANSACTION_DATE,
        ACCOUNTING_PERIOD,
        FISCAL_YEAR,
        VENDOR_ID,
        ORIGIN_SYSTEM,
        GL_BUSINESS_UNIT,
        GL_DEPT_STR,
        PROC_ACTIV_STR,
        BUDGET_ACCNT_STR,
        COST_CLASS_STR,
        ACTUAL_HOURS,
        ACTUAL_COST,
        LOAD_DATE,
        LAST_UPDATE_DATE,
        Z_UPDATE_FLAG
    FROM FINAL_FLOW
