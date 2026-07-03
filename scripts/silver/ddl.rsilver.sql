
 /*
====================================================================================
DDL Script : Create Bronze Tables
====================================================================================
script purpose :
	This script create tables in the 'bronze' schema, dropping existing tables
	if they are already exist.
	Run this script to re_define the ddl structure of ' bronze' tables.
=====================================================================================
*/

if OBJECT_ID('rsilver.crm_cust_info','U') IS NOT NULL
	DROP TABLE rsilver.crm_cust_info;
GO


create table rsilver.crm_cust_info(
cst_id int,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_marital_status nvarchar(50),
cst_gender nvarchar(50),
cst_create_date date,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);

GO

if OBJECT_ID('rsilver.crm_pred_info','U') IS NOT NULL
	DROP TABLE rsilver.crm_pred_info

create table rsilver.crm_pred_info(
prd_id int,
cat_id nvarchar(50),
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost int,
prd_line nvarchar(50),
prd_start_dt date,
prd_end_dt date,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

if OBJECT_ID('rsilver.crm_sales_details ','U') IS NOT NULL
	DROP TABLE rsilver.crm_sales_details ;
GO

create table rsilver.crm_sales_details  (
sls_ord_num nvarchar(50),
sls_prd_key nvarchar(50),
sls_cust_id int,
sls_order_dt date,
sls_ship_dt  date,
sls_due_dt  date,
sls_sales   int,
sls_quantity  int,
sls_price  int,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

if OBJECT_ID('rsilver.erp_cust_az12','U') IS NOT NULL
	DROP TABLE rsilver.erp_cust_az12;
GO

create table rsilver.erp_cust_az12(
cid nvarchar(50),
bdate date,
gen nvarchar(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('rsilver.erp_loc_a101') IS NOT NULL
	DROP TABLE  rsilver.erp_loc_a101;
GO

create table rsilver.erp_loc_a101 (
cid nvarchar(50),
cntry nvarchar(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO

IF OBJECT_ID('rsilver.erp_px_cat_g1v2') IS NOT NULL
	DROP TABLE rsilver.erp_px_cat_g1v2;
GO

create table rsilver.erp_px_cat_g1v2 (
id nvarchar(50),
cat  nvarchar(50),
subcat  nvarchar(50),
maintenance  nvarchar(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO
