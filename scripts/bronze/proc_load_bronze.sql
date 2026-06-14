/*
================================================================================
Stored Procedure : Load Bronze Layer (source -> Bronze)
================================================================================
Script Purpose:
	This stored procedure load the data into 'rbronze' schema from external CSV files.
	It performs the following actions:
		-Truncate the bronze tables before loading data.
		-Uses the 'BULK INSERT' command to load data from csv files to bronze tables.

		parameters:
			None.
		  This stored procedure doesnot accept any parameters or return any values.

		Usage Examlpes:
		    EXEC rbronze.load_rbronze;
==================================================================================
*/

CREATE OR ALTER PROCEDURE rbronze.load_rbronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time datetime, @batch_end_time datetime;
	--ADD TRY..CATCH :ENSURE ERROR HANDLING,DATA INTEGRITY
	--AND ISSUE LOGGING FOR EASY DEBUGGING
	BEGIN TRY
			set @batch_start_time = GETDATE();
			print '=========================================';
			print 'Loading Bronze Layer' ;
			print '=========================================';

			print '_________________________________________';
			print 'Loading CRM TABLE'  ;
			print '_________________________________________';

			SET @start_time = GETDATE();
			PRINT '>> TRUNCATING TABLE : rbronze.crm_cust_info '
			TRUNCATE TABLE rbronze.crm_cust_info;

			--TRUNCATE:QUICKLY DELETE ALL ROWS FROM THE TABLE ,RESETTING IT TO 
			--AN EMPTY STATE,THEN BULK:INSERT DATA TO EMPTY TABLE

			PRINT '>> INSERTING DATA INTO : rbronze.crm_cust_info'
			BULK INSERT rbronze.crm_cust_info
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_crm\cust_info.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',' ,
				TABLOCK
			);
			SET @end_time = GETDATE();
			--datediff():calculate the diff. between two dates,return days, monthes or years.
			PRINT '>>LOAD DURATION : ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'second' ;
			print '>>__________________'

			set @start_time = getdate();
			PRINT '>> TRUNCATING TABLE : rbronze.crm_pred_info '
			TRUNCATE TABLE rbronze.crm_pred_info

			PRINT '>> INSERTING DATA INTO : rbronze.crm_pred_info '
			BULK INSERT rbronze.crm_pred_info
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_crm\prd_info.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
			set @end_time = getdate();
			print '>>loading duration : ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds' ;
			print '>>__________________'
			--CHECK NO. OF ROWS IN TABLE
			--SELECT COUNT(*) FROM rbronze.crm_pred_info

			set @start_time = getdate();
			PRINT '>> TRUNCATING TABLE : rbronze.crm_sales_details '
			TRUNCATE TABLE rbronze.crm_sales_details ;

			PRINT '>> INSERTING DATA INTO : rbronze.crm_sales_details '
			BULK INSERT rbronze.crm_sales_details 
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_crm\sales_details.csv'
			WITH (
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
			set @end_time = GETDATE();
			print '>>LOADING DURATION : ' + CAST(DATEDIFF(second, @start_time, @end_time) as nvarchar) + 'seconds' ;
			print '>>__________________'

			print '_________________________________________';
			print 'Loading ERP TABLE'  ;
			print '_________________________________________';

			set @start_time = GETDATE();
			PRINT '>> TRUNCATING TABLE : rbronze.erp_cust_az12'
			TRUNCATE TABLE rbronze.erp_cust_az12;

			PRINT '>> INSERTING DATA INTO : rbronze.erp_cust_az12'
			BULK INSERT rbronze.erp_cust_az12
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_erp\CUST_AZ12.csv'
			WITH (
				FIRSTROW = 2 ,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
			SET @end_time = GETDATE()
			PRINT '>>LOADING DURATION : ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds' ;
			print '>>__________________'

			set @start_time = GETDATE()
			PRINT'>> TRUNCATING TABLE : rbronze.erp_loc_a101 '
			TRUNCATE TABLE  rbronze.erp_loc_a101  ;

			PRINT '>> INSERTING DATA INTO : rbronze.erp_loc_a101 '
			BULK INSERT  rbronze.erp_loc_a101 
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_erp\LOC_A101.csv'
			WITH (
				FIRSTROW = 2 ,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
			set @end_time = GETDATE()
			PRINT '>>LOADING DURATION : ' + cast(datediff(second,@start_time, @end_time) as nvarchar) + 'seconds' ;
			print '>>__________________'

			set @start_time = GETDATE();
			PRINT'>> TRUNCATING TABLE : rbronze.erp_px_cat_g1v2'
			TRUNCATE TABLE rbronze.erp_px_cat_g1v2

			PRINT '>> INSERTING DATA INTO : rbronze.erp_px_cat_g1v2'
			BULK INSERT rbronze.erp_px_cat_g1v2
			FROM 'D:\rehab dro.io\sql-data-warehouse-project-main\datasets\source_erp\PX_CAT_G1V2.csv'
			WITH (
				FIRSTROW = 2 ,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
			set @end_time = GETDATE();
			PRINT '>>LOADING DURATION : ' + cast(datediff(second, @start_time ,@end_time) as nvarchar) + 'seconds' ;
			print '>>__________________'
		set @batch_end_time = getdate();
		PRINT'========================================';
		print' loading bronze layer is completed';
		print ' TOTAL LOAD DURATION :'+ CAST(DATEDIFF(second, @batch_start_time,@batch_end_time ) as nvarchar) + 'secondas';
		PRINT'========================================';
    END TRY 
	BEGIN CATCH
		PRINT'========================================';
		PRINT'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT'ERROR MEASSAGE' + ERROR_MESSAGE();
		PRINT'ERROR MESSAGE' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT'ERROR MESSAGE' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT'========================================';
	END CATCH
END
