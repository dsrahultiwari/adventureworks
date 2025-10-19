/*==============================================================================
 Project:        Retail DW – Transformation Layer (HOP1)
 File:           02.load_hop1_data.sql
 Description:    Loads standardized data from staging (tbl_stg_*) into
                 first-hop transformed tables (tbl_trans_hop1_*).
                 Only INSERT...SELECT statements; no keys, constraints, or indexes.

 Layer:          HOP1 (Transformation/Staging)
 Author:         DAG14
 Created:        2025-10-19
-------------------------------------------------------------------------------
 Contents
   1) PRODUCT CATEGORIES & SUBCATEGORIES
   2) PRODUCTS
   3) CUSTOMERS (with light standardization)
   4) TERRITORIES
   5) SALES (order line items)
-------------------------------------------------------------------------------
 Conventions & Notes
 - Naming:   tbl_trans_hop1_*  → first transformation hop
 - Source:   tbl_stg_*         → raw/staging landing tables
 - Policy:   No PK/FK/constraints/indexes in this script (per requirement)
==============================================================================*/

--------------------------------------------------------------------------------
-- 1) PRODUCT CATEGORIES & SUBCATEGORIES
--    Simple pass-through loads from staging to HOP1
--------------------------------------------------------------------------------
INSERT INTO tbl_trans_hop1_prodsubcat
SELECT *
FROM tbl_stg_prodsubcat;

INSERT INTO tbl_trans_hop1_prodcat
SELECT *
FROM tbl_stg_prodcat;

--------------------------------------------------------------------------------
-- 2) PRODUCTS
--    Direct copy to HOP1 (schema-aligned)
--------------------------------------------------------------------------------
INSERT INTO tbl_trans_hop1_products
SELECT *
FROM tbl_stg_products;

--------------------------------------------------------------------------------
-- 3) CUSTOMERS
--    Light transformations:
--      - customername = COALESCE prefix + first + last
--      - age = DATEDIFF(CURDATE(), birthdate)/365 (approx years)
--      - maritalstatus map: 'S'→'Single' else 'Married'
--      - gender map: 'M'→'Male', 'F'→'Female', else 'Did Not Disclose'
--      - homeowner map: 'Y'→'Yes' else 'No'
--------------------------------------------------------------------------------
INSERT INTO tbl_trans_hop1_customers
SELECT 
    customerkey, 
    CONCAT(IFNULL(prefix, 'NA.'), ' ', firstname, ' ', lastname) AS customername,
    birthdate,
    DATEDIFF(CURDATE(), birthdate) / 365 AS age,
    CASE 
        WHEN MaritalStatus = 'S' THEN 'Single'
        ELSE 'Married'
    END AS maritalstatus,
    CASE 
        WHEN gender = 'M' THEN 'Male'
        WHEN gender = 'F' THEN 'Female'
        ELSE 'Did Not Disclose'
    END AS gender,
    emailaddress,
    annualincome,
    totalchildren,
    educationlevel,
    occupation,
    CASE 
        WHEN homeowner = 'Y' THEN 'Yes'
        ELSE 'No'
    END AS homeowner
FROM tbl_stg_customers;

--------------------------------------------------------------------------------
-- 4) TERRITORIES
--    Direct copy from staging
--------------------------------------------------------------------------------
INSERT INTO tbl_trans_hop1_territories
SELECT *
FROM tbl_stg_territories;

--------------------------------------------------------------------------------
-- 5) SALES (Order Line Items)
--    Direct copy to HOP1
--------------------------------------------------------------------------------
INSERT INTO tbl_trans_hop1_sales
SELECT 
    OrderDate,
    StockDate,
    OrderNumber,
    ProductKey,
    CustomerKey,
    TerritoryKey,
    OrderLineItem,
    OrderQuantity
FROM tbl_stg_sales;

-- End of file
