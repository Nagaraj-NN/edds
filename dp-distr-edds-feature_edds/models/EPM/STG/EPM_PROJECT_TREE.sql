-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_TREE_TABLES.sql
-- MAPPING NAME      : PROJECT_TREE
-- TARGET TABLE      : EDDSP.EPM.EPM_PROJECT_TREE
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_TREE_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_GL_DEPT_TREE.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    materialized='incremental',
    incremental_strategy='append',
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_TREE_TABLES_ASYS'),
        "TRUNCATE TABLE IF EXISTS {{ this }}"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_TREE_TABLES_ASYS')
    ]
) }}

WITH SQ_TREENODE AS
(
    SELECT
        N.SETID,
        RTRIM(N.SETCNTRLVALUE) AS SETCNTRLVALUE,
        RTRIM(N.TREE_NAME) AS TREE_NAME,
        RTRIM(N.TREE_NODE) AS TREE_NODE,
        N.EFFDT,
        N.TREE_LEVEL_NUM,
        N.PARENT_NODE_NUM
    FROM {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */ AS N
    WHERE N.SETCNTRLVALUE IN ('CHAIR','CRPDV','DISTR','TDOTH','FINAN','LEGAL','NONBU','NUNRG','NUOTH','NUREG','SHSVC','TCOMM','TRANS','VICHR','WSNRG','WSOTH','WSREG')
      AND N.TREE_NAME IN ('CHAIRMAN','CORP_DEV','DISTRIBUTION','TD_OTHER','FINANCE_ANALYSIS','NONBU_PROJECTS','LEGAL','NUCLEAR_NON_REG','NUCLEAR_OTHER','NUCLEAR_REG','SHARED_SERVICES','TELECOM','TRANSMISSION','VICE_CHAIRMAN','WHOLESALE_NON_REG','WHOLESALE_OTHER','WHOLESALE_REG')
      AND N.EFFDT =
          (
              SELECT MAX(D.EFFDT)
              FROM {{ source('CRPDB01_EPMADM', 'PSTREEDEFN') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREEDEFN */ AS D
              WHERE D.SETID = N.SETID
                AND D.TREE_NAME = N.TREE_NAME
                AND D.SETCNTRLVALUE = N.SETCNTRLVALUE
          )
),
LKP_PARENT_PROJECT AS
(
    SELECT
        C.SETID,
        C.SETCNTRLVALUE,
        C.TREE_NAME,
        C.TREE_NODE AS CHILD_PROJECT_STR,
        P.TREE_NODE AS PARENT_PROJECT_STR,
        C.TREE_LEVEL_NUM AS DESCENDANT_LEVEL
    FROM SQ_TREENODE AS C
    LEFT JOIN {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */ AS P
        ON P.SETID = C.SETID
       AND P.SETCNTRLVALUE = C.SETCNTRLVALUE
       AND P.TREE_NAME = C.TREE_NAME
       AND P.EFFDT = C.EFFDT
       AND P.TREE_NODE_NUM = C.PARENT_NODE_NUM
),
LKP_PROJ_DESCR AS
(
    SELECT
        T.CHILD_PROJECT_STR,
        CP.DESCR AS CHILD_PROJECT_DESC,
        T.PARENT_PROJECT_STR,
        PP.DESCR AS PARENT_PROJECT_DESC,
        T.DESCENDANT_LEVEL,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM LKP_PARENT_PROJECT AS T
    LEFT JOIN {{ source('CRPDB01_EPMADM', 'PS_PROJECT_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJECT_D00 */ AS CP
        ON CP.BUSINESS_UNIT = T.SETCNTRLVALUE
       AND CP.PROJECT_ID = T.CHILD_PROJECT_STR
    LEFT JOIN {{ source('CRPDB01_EPMADM', 'PS_PROJECT_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_PROJECT_D00 */ AS PP
        ON PP.BUSINESS_UNIT = T.SETCNTRLVALUE
       AND PP.PROJECT_ID = T.PARENT_PROJECT_STR
)
SELECT
    CHILD_PROJECT_STR,
    CHILD_PROJECT_DESC,
    PARENT_PROJECT_STR,
    PARENT_PROJECT_DESC,
    DESCENDANT_LEVEL,
    LOAD_DATE
FROM LKP_PROJ_DESCR
