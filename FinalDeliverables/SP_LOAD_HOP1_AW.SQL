/*==============================================================================
 Project:        Retail DW – Transformation Layer (HOP1)
 File:           03.sp_load_hop1.sql
 Procedure:      SP_LOAD_HOP1
 Description:    Loads standardized data from staging (tbl_stg_*) into
                 first-hop transformed tables (tbl_trans_hop1_*), and writes
                 per-table row-count audit entries to TBL_SYS_AUDIT_CONTROL_AW.

 Layer:          HOP1 (Transformation/Staging)
 Author:         DAG14
 Created:        2025-10-26
-------------------------------------------------------------------------------
 Prerequisites
 - Tables created by: 01.sp_create_tables.sql
 - Staging sources populated: tbl_stg_customers, tbl_stg_products,
   tbl_stg_prodsubcat, tbl_stg_prodcat, tbl_stg_territories, tbl_stg_sales
 - (Optional) Target HOP1 tables are empty prior to load if 1:1 count checks
   are expected to match (otherwise counts can legitimately differ).

 Audit Strategy
 - For each source→target load:
     1) Count source rows
     2) INSERT … SELECT into target
     3) Count target rows
     4) Compare counts and log result into TBL_SYS_AUDIT_CONTROL_AW

 Contents
   1) DECLARATIONS & METADATA
   2) LOAD: CUSTOMERS (with light standardization)
   3) LOAD: PRODUCTS
   4) LOAD: PRODUCT SUBCATEGORIES
   5) LOAD: PRODUCT CATEGORIES
   6) LOAD: TERRITORIES
   7) LOAD: SALES (order line items)

 Conventions & Notes
 - Naming:  tbl_stg_* → raw/staging;  tbl_trans_hop1_* → first-hop transforms
 - Policy:  Only INSERT…SELECT transformations; integrity keys handled later
 - Caution: If targets are not truncated, TARGET_COUNT reflects cumulative rows
            (which can intentionally differ from SOURCE_COUNT).
==============================================================================*/

DELIMITER $$

CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_LOAD_HOP1`()
BEGIN

    /*---------------------------------------------------------------------------
     1) DECLARATIONS & METADATA
    ---------------------------------------------------------------------------*/
    DECLARE SOURCE_TABLE   VARCHAR(30);
    DECLARE SOURCE_COUNT   INT;
    DECLARE TARGET_TABLE   VARCHAR(30);
    DECLARE TARGET_COUNT   INT;
    DECLARE PROCESS_NAME   VARCHAR(30);
    DECLARE OPERATION_TYPE VARCHAR(100);
    DECLARE LOG_DETAILS    VARCHAR(100);

    /*---------------------------------------------------------------------------
     2) LOAD: CUSTOMERS
         - Light transformations:
           * customername = COALESCE(prefix,'NA.') + first + last
           * age ≈ DATEDIFF(CURDATE(), birthdate)/365
           * maritalstatus: 'S'→'Single', else 'Married'
           * gender: 'M'→'Male', 'F'→'Female', else 'Did Not Disclose'
           * homeowner: 'Y'→'Yes', else 'No'
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_CUSTOMERS'            INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_CUSTOMERS'     INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 CUSTOMER TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_customers;

    INSERT INTO tbl_trans_hop1_customers
    SELECT 
        customerkey, 
        CONCAT(IFNULL(prefix, 'NA.'), ' ', firstname, ' ', lastname) AS customername,
        birthdate,
        DATEDIFF(CURDATE(), birthdate) / 365 AS age,
        CASE WHEN maritalstatus = 'S' THEN 'Single' ELSE 'Married' END AS maritalstatus,
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
        CASE WHEN homeowner = 'Y' THEN 'Yes' ELSE 'No' END AS homeowner
    FROM tbl_stg_customers;

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_customers;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

    /*---------------------------------------------------------------------------
     3) LOAD: PRODUCTS
         - Direct pass-through (schema-aligned)
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_PRODUCTS'             INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_PRODUCTS'      INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 PRODUCTS TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_products;

    INSERT INTO tbl_trans_hop1_products
    SELECT * FROM tbl_stg_products;

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_products;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

    /*---------------------------------------------------------------------------
     4) LOAD: PRODUCT SUBCATEGORIES
         - Direct pass-through
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_PRODSUBCAT'           INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_PRODSUBCAT'    INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 PRODUCT SUBCATEGORY TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_prodsubcat;

    INSERT INTO tbl_trans_hop1_prodsubcat
    SELECT * FROM tbl_stg_prodsubcat;

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_prodsubcat;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

    /*---------------------------------------------------------------------------
     5) LOAD: PRODUCT CATEGORIES
         - Direct pass-through
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_PRODCAT'              INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_PRODCAT'       INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 PRODUCT CATEGORY TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_prodcat;

    INSERT INTO tbl_trans_hop1_prodcat
    SELECT * FROM tbl_stg_prodcat;

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_prodcat;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

    /*---------------------------------------------------------------------------
     6) LOAD: TERRITORIES
         - Direct pass-through
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_TERRITORIES'          INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_TERRITORIES'   INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 TERRITORIES TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_territories;

    INSERT INTO tbl_trans_hop1_territories
    SELECT * FROM tbl_stg_territories;

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_territories;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

    /*---------------------------------------------------------------------------
     7) LOAD: SALES (Order Line Items)
         - Direct pass-through (explicit column list)
    ---------------------------------------------------------------------------*/
    SELECT 'TBL_STG_SALES'                INTO SOURCE_TABLE;
    SELECT 'TBL_TRANS_HOP1_SALES'         INTO TARGET_TABLE;
    SET PROCESS_NAME   = 'SP_LOAD_HOP1';
    SET OPERATION_TYPE = 'LOADING HOP1 SALES TABLE';

    SELECT COUNT(*) INTO SOURCE_COUNT FROM tbl_stg_sales;

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

    SELECT COUNT(*) INTO TARGET_COUNT FROM tbl_trans_hop1_sales;

    IF SOURCE_COUNT <> TARGET_COUNT THEN
        SET LOG_DETAILS = 'THERE IS A MISMATCH IN THE COUNT, NEED TO CHECK THE FLOW';
    ELSE
        SET LOG_DETAILS = 'THERE IS NO MISMATCH, DATA LOADED SUCCESSFULLY';
    END IF;

    INSERT INTO TBL_SYS_AUDIT_CONTROL_AW
    (
        SOURCE_NAME, TARGET_NAME, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, OPERATED_BY, OPERATION_DATE
    )
    VALUES
    (
        SOURCE_TABLE, TARGET_TABLE, SOURCE_COUNT, TARGET_COUNT,
        PROCESS_NAME, OPERATION_TYPE, LOG_DETAILS, CURRENT_USER(), CURRENT_TIMESTAMP()
    );

END$$

DELIMITER ;
