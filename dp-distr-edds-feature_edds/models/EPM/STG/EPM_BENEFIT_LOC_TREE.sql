-- ============================================================
-- CONVERSION SUMMARY
-- SOURCE FILE       : LOAD_EDDS_TREE_TABLES.sql
-- MAPPING NAME      : BENLOC_TREE
-- TARGET TABLE      : EDDSP.EPM.EPM_BENEFIT_LOC_TREE
-- AUTOSYS_JOB_NAME  : LOAD_EDDS_TREE_TABLES_ASYS
-- MATERIALIZATION   : table
-- ============================================================
-- ============================================================
-- CHANGE LOG (2026-09-12)
-- RENAMED : was EPM_PROC_ACTIV_TREE.sql; the file name now matches the table this model builds.
-- CHANGED : the pre-hook TRUNCATE now targets this model's own table,
--           with IF EXISTS. It used source() on the same table, which in
--           CI is the real dev table. Nothing else in the model changed.
-- ============================================================

{{ config(
    materialized='incremental',
    incremental_strategy='append',
    full_refresh=false,
    pre_hook=[
        log_model_start(this, 'LOAD_EDDS_TREE_TABLES_ASYS'),
        "TRUNCATE TABLE IF EXISTS {{ this }}"
    ],
    post_hook=[
        log_model_end(this, 'LOAD_EDDS_TREE_TABLES_ASYS')
    ]
) }}
with
SQ_BENLOC_TREE_1 AS
(
    SELECT Q.$1 AS C1, Q.$2 AS C2, Q.$3 AS C3, Q.$4 AS C4, Q.$5 AS C5
    FROM (
SELECT RTRIM(a.tree_node)  child,

       RTRIM(a.descr)  child_descr,

       RTRIM(b.tree_node)  parent,

       RTRIM(b.descr) parent_descr,

       c.tree_level_num  tree_level

  FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ a,

       {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ b,

       {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */ c,

       {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */ d

 WHERE c.setid = 'AEP'

   AND c.tree_name = 'BENEFITING_LOC'

   AND c.effdt =

           (SELECT MAX(effdt)

              FROM {{ source('CRPDB01_EPMADM', 'PSTREEDEFN') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREEDEFN */ c1

             WHERE c1.setid = c.setid

               AND c1.tree_name = c.tree_name

               AND c1.setcntrlvalue = c.setcntrlvalue)

   AND c.setid = d.setid

   AND c.setcntrlvalue = d.setcntrlvalue

   AND c.tree_name = d.tree_name

   AND c.effdt = d.effdt

   AND c.parent_node_num = d.tree_node_num

   AND a.setid = c.setid

   AND a.tree_node = c.tree_node

   AND a.effdt = (SELECT MAX(effdt)

                    FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ a1

                   WHERE a1.setid = a.setid AND a1.tree_node = a.tree_node)

   AND b.setid = d.setid

   AND b.tree_node = d.tree_node

   AND b.effdt = (SELECT MAX(effdt)

                    FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ b1

                   WHERE b1.setid = b.setid AND b1.tree_node = b.tree_node)

UNION

SELECT RTRIM(a.tree_node)  child,

       RTRIM(a.descr)  child_descr,

       ''  parent,

       ''  parent_descr,

       b.tree_level_num  tree_level

  FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ a, {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */ b

 WHERE b.setid = 'AEP'

   AND b.tree_name = 'BENEFITING_LOC'

   AND b.effdt =

           (SELECT MAX(effdt)

              FROM {{ source('CRPDB01_EPMADM', 'PSTREEDEFN') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREEDEFN */ b1

             WHERE b1.setid = b.setid

               AND b1.tree_name = b.tree_name

               AND b1.setcntrlvalue = b.setcntrlvalue)

   AND b.tree_level_num = 1

   AND a.setid = b.setid

   AND a.tree_node = b.tree_node

   AND a.effdt = (SELECT MAX(effdt)

                    FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */ a1

                   WHERE a1.setid = a.setid AND a1.tree_node = a.tree_node)

ORDER BY tree_level
    ) AS Q
),
SQ_BENLOC_TREE_2 AS
(
    SELECT Q.$1 AS C1, Q.$2 AS C2, Q.$3 AS C3, Q.$4 AS C4, Q.$5 AS C5
    FROM (
SELECT (B.TREE_NODE), (B.DESCR), D.TREE_LEVEL_NUM + 1, (A.Z_BENEFIT_LOC), (A.DESCR) 

FROM

 {{ source('CRPDB01_EPMADM', 'PS_Z_BENLOC_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_BENLOC_D00 */  A, {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */  B,{{ source('CRPDB01_EPMADM', 'PSTREELEAF') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREELEAF */  C, {{ source('CRPDB01_EPMADM', 'PSTREENODE') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREENODE */  D

WHERE C.SETID = 'AEP' 

AND C.TREE_NAME = 'BENEFITING_LOC'

AND C.EFFDT = ( SELECT MAX(EFFDT) 

     FROM {{ source('CRPDB01_EPMADM', 'PSTREELEAF') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PSTREELEAF */  C1

     WHERE C1.SETID = C.SETID

     AND C1.TREE_NAME = C.TREE_NAME)

AND C.SETID = D.SETID

AND C.SETCNTRLVALUE = D.SETCNTRLVALUE

AND C.TREE_NAME = D.TREE_NAME

AND C.EFFDT = D.EFFDT

AND C.TREE_NODE_NUM = D.TREE_NODE_NUM

AND A.SETID = C.SETID

AND A.Z_BENEFIT_LOC BETWEEN C.RANGE_FROM AND C.RANGE_TO

AND A.EFFDT = ( SELECT MAX(EFFDT) 

     FROM {{ source('CRPDB01_EPMADM', 'PS_Z_BENLOC_D00') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_Z_BENLOC_D00 */  A1

     WHERE A1.SETID = A.SETID

     AND A1.Z_BENEFIT_LOC = A.Z_BENEFIT_LOC)

AND B.SETID = D.SETID

AND B.TREE_NODE = D.TREE_NODE

AND B.EFFDT = ( SELECT MAX(EFFDT) 

     FROM {{ source('CRPDB01_EPMADM', 'PS_TREE_NODE_TBL') }} /* CRPDB01_DEV_SANDBOX.EPMADM.PS_TREE_NODE_TBL */  B1

     WHERE B1.SETID = B.SETID

     AND B1.TREE_NODE = B.TREE_NODE)

ORDER BY A.Z_BENEFIT_LOC
    ) AS Q
),
FINAL_BENLOC_TREE AS
(
    SELECT
        C1 AS CHILD_BENEFIT_LOC_STR,
        C2 AS CHILD_BENEFIT_LOC_DESC,
        C3 AS PARENT_BENEFIT_LOC_STR,
        C4 AS PARENT_BENEFIT_LOC_DESC,
        CAST(C5 AS NUMBER(38,18)) AS DESCENDANT_LEVEL,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM SQ_BENLOC_TREE_1

    UNION ALL

    SELECT
        C4 AS CHILD_BENEFIT_LOC_STR,
        C5 AS CHILD_BENEFIT_LOC_DESC,
        C1 AS PARENT_BENEFIT_LOC_STR,
        C2 AS PARENT_BENEFIT_LOC_DESC,
        CAST(C3 AS NUMBER(38,18)) AS DESCENDANT_LEVEL,
        CURRENT_TIMESTAMP() AS LOAD_DATE
    FROM SQ_BENLOC_TREE_2
)

SELECT
    CAST(CHILD_BENEFIT_LOC_STR AS VARCHAR(20))  AS CHILD_BENEFIT_LOC_STR,
    CAST(CHILD_BENEFIT_LOC_DESC AS VARCHAR(40)) AS CHILD_BENEFIT_LOC_DESC,
    CAST(PARENT_BENEFIT_LOC_STR AS VARCHAR(20)) AS PARENT_BENEFIT_LOC_STR,
    CAST(PARENT_BENEFIT_LOC_DESC AS VARCHAR(40)) AS PARENT_BENEFIT_LOC_DESC,
    CAST(DESCENDANT_LEVEL AS NUMBER(38,18))     AS DESCENDANT_LEVEL,
    CAST(LOAD_DATE AS TIMESTAMP_NTZ(9))         AS LOAD_DATE
FROM FINAL_BENLOC_TREE
