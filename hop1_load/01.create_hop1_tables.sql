/*==============================================================================
 Project:        Retail DW – Transformation Layer (HOP1)
 File:           01.create_hop1_tables.sql
 Description:    Defines first-hop transformed tables for the analytics warehouse.
                 These tables are cleaned/standardized from raw ingestion and
                 normalized for downstream modeling into star schemas (dim/fact).

 Layer:          HOP1 (Transformation/Staging with Constraints)
 Author:         DAG14
 Created:        2025-10-19
-------------------------------------------------------------------------------
 Contents
   1) Conventions & Notes
   2) DDL: Categories & Subcategories
   3) DDL: Products
   4) DDL: Customers
   5) DDL: Territories
   6) DDL: Sales (transactional lines)
   7) Indexes
   8) Data Quality Constraints (CHECKs)
   9) Post-DDL QA Snippets (commented)
-------------------------------------------------------------------------------
 Conventions & Notes
 - Naming:   tbl_trans_hop1_*  → first transformation hop
==============================================================================*/

--------------------------------------------------------------------------------
-- 2) PRODUCT CATEGORIES & SUBCATEGORIES
--------------------------------------------------------------------------------
CREATE TABLE tbl_trans_hop1_prodsubcat
(
    ProductSubcategoryKey INT,
    SubcategoryName VARCHAR(20),
    ProductCategoryKey INT
);

CREATE TABLE tbl_trans_hop1_prodcat
(
    ProductCategoryKey INT,
    CategoryName VARCHAR(15)
);

--------------------------------------------------------------------------------
-- 3) PRODUCTS
--------------------------------------------------------------------------------

CREATE TABLE tbl_trans_hop1_products
(
    ProductKey INT,
    ProductSubcategoryKey INT,
    ProductSKU VARCHAR(10),
    ProductName VARCHAR(50),
    ModelName VARCHAR(30),
    ProductDescription VARCHAR(250),
    ProductColor VARCHAR(15),
    ProductSize VARCHAR(5),
    ProductStyle CHAR(1),
    ProductCost DECIMAL(6,2),
    ProductPrice DECIMAL(6,2)
);

--------------------------------------------------------------------------------
-- 4) CUSTOMERS
--------------------------------------------------------------------------------
CREATE TABLE tbl_trans_hop1_customers
(
    customerkey INT,
    customername VARCHAR(50),
    birthdate DATE,
    age INT,
    maritalstatus VARCHAR(10),
    gender VARCHAR(20),
    emailaddress VARCHAR(50),
    annualincome INT,
    totalchildren INT,
    educationlevel VARCHAR(20),
    occupation VARCHAR(20),
    homeowner VARCHAR(5)
);

--------------------------------------------------------------------------------
-- 5) TERRITORIES
--------------------------------------------------------------------------------
CREATE TABLE tbl_trans_hop1_territories
(
    TerritoryKey INT,
    Region VARCHAR(15),
    Country VARCHAR(15),
    Continent VARCHAR(15)
);

--------------------------------------------------------------------------------
-- 6) SALES (Order Line Items)
--------------------------------------------------------------------------------
CREATE TABLE tbl_trans_hop1_sales
(
    OrderDate DATE,
    StockDate DATE,
    OrderNumber VARCHAR(10),
    ProductKey INT,
    CustomerKey INT,
    TerritoryKey INT,
    OrderLineItem INT,
    OrderQuantity INT
);

-- End of file
