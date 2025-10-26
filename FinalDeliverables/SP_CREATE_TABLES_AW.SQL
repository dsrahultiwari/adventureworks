/*==============================================================================
 Project:        Retail DW – HOP1 Table Provisioning (DDL + Audit)
 File:           01.sp_create_tables.sql
 Procedure:      SP_CREATE_TABLES
 Description:    Idempotent DDL to (re)create first-hop transformed tables
                 (tbl_trans_hop1_*) and the system audit/control table.
                 Performs a post-create validation using INFORMATION_SCHEMA
                 and logs a summary entry to TBL_SYS_AUDIT_CONTROL_AW.

 Layer:          HOP1 (Transformation/Staging)
 Author:         DAG14
 Created:        2025-10-26
-------------------------------------------------------------------------------
 Prerequisites
 - Target schema exists (e.g., ADVENTUREWORKS) and is the active database.
 - Executing user has CREATE/DROP/INSERT privileges.

 Contents
   1) DECLARATIONS & INITIALIZATION
   2) AUDIT/CONTROL TABLE (TBL_SYS_AUDIT_CONTROL_AW)
   3) HOP1 TABLES (DROP + CREATE)
        3.1) Product Subcategories
        3.2) Product Categories
        3.3) Products
        3.4) Customers
        3.5) Territories
        3.6) Sales (order line items)
   4) POST-CREATE VALIDATION (INFORMATION_SCHEMA count)
   5) AUDIT LOG INSERT

 Conventions & Notes
 - Naming:   tbl_trans_hop1_*  → first transformation hop tables
 - Policy:   No PK/FK/constraints/indexes beyond what’s specified here.
 - Idempotent: Each table is dropped if it exists, then recreated.
 - Validation: Compares total table count in schema to an expected number.
               Adjust the expected count as your schema evolves.
==============================================================================*/

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CREATE_TABLES`()
BEGIN

    /*----------------------------------------------------------------------------
     1) DECLARATIONS & INITIALIZATION
    ----------------------------------------------------------------------------*/
    DECLARE TABLE_COUNT   INT;
    DECLARE OPERATION_TYPE VARCHAR(100);
    DECLARE LOG_DETAILS    VARCHAR(100);
    DECLARE PROCESS_NAME   VARCHAR(30);

    SET OPERATION_TYPE = 'CREATING THE TABLE FOR ALL THE LAYERS';
    SET PROCESS_NAME   = 'SP_CREATE_TABLES';

    /*----------------------------------------------------------------------------
     2) AUDIT/CONTROL TABLE
         - Holds one-line operational summaries for major procedures.
         - OPID is an auto-incrementing surrogate key.
    ----------------------------------------------------------------------------*/
    DROP TABLE IF EXISTS TBL_SYS_AUDIT_CONTROL_AW;
    CREATE TABLE TBL_SYS_AUDIT_CONTROL_AW (
        OPID           INT PRIMARY KEY AUTO_INCREMENT,
        SOURCE_NAME    VARCHAR(30),
        TARGET_NAME    VARCHAR(30),
        SOURCE_COUNT   INT,
        TARGET_COUNT   INT, 
        PROCESS_NAME   VARCHAR(30),
        OPERATION_TYPE VARCHAR(100),
        LOG_DETAILS    VARCHAR(100),
        OPERATED_BY    VARCHAR(20),
        OPERATION_DATE TIMESTAMP
    );

    /*----------------------------------------------------------------------------
     3) HOP1 TABLES (DROP + CREATE)
        Note: These are pure container tables for first-hop transformed data.
              Keys/constraints can be added later in dimensional layers if needed.
    ----------------------------------------------------------------------------*/

    /*-- 3.1) Product Subcategories ------------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_prodsubcat;
    CREATE TABLE tbl_trans_hop1_prodsubcat
    (
        ProductSubcategoryKey INT,
        SubcategoryName       VARCHAR(20),
        ProductCategoryKey    INT
    );

    /*-- 3.2) Product Categories ---------------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_prodcat;
    CREATE TABLE tbl_trans_hop1_prodcat
    (
        ProductCategoryKey INT,
        CategoryName       VARCHAR(15)
    );

    /*-- 3.3) Products -------------------------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_products;
    CREATE TABLE tbl_trans_hop1_products
    (
        ProductKey         INT,
        ProductSubcategoryKey INT,
        ProductSKU         VARCHAR(10),
        ProductName        VARCHAR(50),
        ModelName          VARCHAR(30),
        ProductDescription VARCHAR(250),
        ProductColor       VARCHAR(15),
        ProductSize        VARCHAR(5),
        ProductStyle       CHAR(1),
        ProductCost        DECIMAL(6,2),
        ProductPrice       DECIMAL(6,2)
    );

    /*-- 3.4) Customers ------------------------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_customers;
    CREATE TABLE tbl_trans_hop1_customers
    (
        customerkey    INT,
        customername   VARCHAR(50),
        birthdate      DATE,
        age            INT,
        maritalstatus  VARCHAR(10),
        gender         VARCHAR(20),
        emailaddress   VARCHAR(50),
        annualincome   INT,
        totalchildren  INT,
        educationlevel VARCHAR(20),
        occupation     VARCHAR(20),
        homeowner      VARCHAR(5)
    );

    /*-- 3.5) Territories ----------------------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_territories;
    CREATE TABLE tbl_trans_hop1_territories
    (
        TerritoryKey INT,
        Region       VARCHAR(15),
        Country      VARCHAR(15),
        Continent    VARCHAR(15)
    );

    /*-- 3.6) Sales (order line items) --------------------------------------------*/
    DROP TABLE IF EXISTS tbl_trans_hop1_sales;
    CREATE TABLE tbl_trans_hop1_sales
    (
        OrderDate     DATE,
        StockDate     DATE,
        OrderNumber   VARCHAR(10),
        ProductKey    INT,
        CustomerKey   INT,
        TerritoryKey  INT,
        OrderLineItem INT,
        OrderQuantity INT
    );

    /*----------------------------------------------------------------------------
     4) POST-CREATE VALIDATION
        - Counts tables in the active schema (here assumed as 'ADVENTUREWORKS').
        - If your schema name differs, update TABLE_SCHEMA accordingly.
        - Expected count is project-specific; adjust from 13 as needed.
    ----------------------------------------------------------------------------*/
    SELECT COUNT(*)
      INTO TABLE_COUNT
      FROM INFORMATION_SCHEMA.TABLES
     WHERE TABLE_SCHEMA = 'ADVENTUREWORKS';

    IF TABLE_COUNT = 13 THEN
        SET LOG_DETAILS = 'ALL THE TABLES ARE CREATED SUCCESSFULLY';
    ELSE
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE TABLE COUNTS';
    END IF;

    /*----------------------------------------------------------------------------
     5) AUDIT LOG INSERT
        - Writes a one-line summary of this operation into the control table.
    ----------------------------------------------------------------------------*/
    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        PROCESS_NAME,
        OPERATION_TYPE,
        LOG_DETAILS,
        OPERATED_BY,
        OPERATION_DATE
    )
    VALUES
    (
        PROCESS_NAME,
        OPERATION_TYPE,
        LOG_DETAILS,
        CURRENT_USER(),
        CURRENT_TIMESTAMP()
    );

END$$

DELIMITER ;
