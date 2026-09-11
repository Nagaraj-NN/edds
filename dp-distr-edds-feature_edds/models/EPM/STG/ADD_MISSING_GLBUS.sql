-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_TREE_TABLES.sql
-- MAPPING NAME      : m_add_missing_glbus
-- TARGET TABLE      : EDDSP.EPM.EPM_GL_BUSINESS_UNIT_TREE
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_TREE_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_BENEFIT_LOC_TREE.sql; the file name now matches the mapping m_add_missing_glbus.
--           Model code unchanged.
-- NOTE    : disabled in dbt_project.yml; the model that loads
--           EPM_GL_BUSINESS_UNIT_TREE is missing from the project.
-- ============================================================

{{ config(
    materialized='view',
    meta={"session_name": "m_add_missing_glbus"},
    pre_hook=[
        log_model_start(this, 'TBD'),
        " INSERT INTO {{ref('EPM_GL_BUSINESS_UNIT_TREE')}}
(
    CHILD_GL_BUSINESS_UNIT,
    CHILD_GL_BUSINESS_UNIT_DESC,
    PARENT_GL_BUSINESS_UNIT,
    PARENT_GL_BUSINESS_UNIT_DESC,
    DESCENDANT_LEVEL,
    LOAD_DATE
)
WITH SQ_PS_BUS_UNIT_TBL_FS AS
(
SELECT {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }}.business_unit, {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }}.descr

  FROM {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }}, {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_GL') }}

 WHERE NOT EXISTS

           (SELECT 1

              FROM {{ source('CRPDB01_EPMADM', 'PSTREELEAF') }} c

             WHERE c.setid = 'AEP'

               AND c.setcntrlvalue = ' '

               AND c.tree_name = 'GL_PRPT_CONS'

               AND c.effdt = (SELECT MAX(d.effdt)

                                FROM {{ source('CRPDB01_EPMADM', 'PSTREEDEFN') }} d

                               WHERE d.setid = c.setid AND d.tree_name = c.tree_name)

               AND {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }}.business_unit = c.range_from)

   AND {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_FS') }}.business_unit = {{ source('CRPDB01_EPMADM', 'PS_BUS_UNIT_TBL_GL') }}.business_unit
),
EXP_DATAQUALITYSTANDARDS1 AS
(
    SELECT TRIM(BUSINESS_UNIT) AS BUSINESS_UNIT, TRIM(DESCR) AS DESCR
    FROM SQ_PS_BUS_UNIT_TBL_FS
),
EXP_SET_VALUES AS
(
    SELECT BUSINESS_UNIT, DESCR, 'NON_CONSOL' AS PARENT_GL_BUSINESS_UNIT, 'Non-consolidated Companies' AS PARENT_GL_BUSINESS_UNIT_DESC, 2 AS DESCENDANT_LEVEL, CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_DATAQUALITYSTANDARDS1
),
AGG_CREATE_PARENT_RECORD AS
(
    SELECT ' ' AS BUSINESS_UNIT, ' ' AS DESCR, PARENT_GL_BUSINESS_UNIT, PARENT_GL_BUSINESS_UNIT_DESC, 1 AS DESCENDANT_LEVEL, CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM EXP_SET_VALUES
    GROUP BY PARENT_GL_BUSINESS_UNIT, PARENT_GL_BUSINESS_UNIT_DESC
),
FINAL_MISSING_GLBUS AS
(
    SELECT BUSINESS_UNIT, DESCR, PARENT_GL_BUSINESS_UNIT, PARENT_GL_BUSINESS_UNIT_DESC, DESCENDANT_LEVEL, LOAD_DATE FROM EXP_SET_VALUES
    UNION ALL
    SELECT BUSINESS_UNIT, DESCR, PARENT_GL_BUSINESS_UNIT, PARENT_GL_BUSINESS_UNIT_DESC, DESCENDANT_LEVEL, LOAD_DATE FROM AGG_CREATE_PARENT_RECORD
)
SELECT * FROM FINAL_MISSING_GLBUS;
 "
],
    post_hook=[
        log_model_end(this, 'DP_DVX1000C_EDW_DAVOX_TRAN_WV90AFT606')
    ]
) }}

SELECT  'This model is  inserting and updating data into EPM_GL_BUSINESS_UNIT_TREE ' AS Model_Description