/*
================================================================
create database and schemas
================================================================
script purpose:
       this script creats a new database named 'ReDataWarehouse' after checking if already exists.
	   if database exists, it is dropped and recreated. additionally, the script sets up 3 schemas
	   with in the database 'rbronze',  'rsilver' , ' rgold'.

warning:
		runing this script will drop the entire 'ReDataWarehouse' databsae if exists.
		all data in database will permenetly deleted. processed with caution
		and ensure you have proper backup before running this script.
		*/

--create database 'dataware house'

use master;
go 


--drop and recreate the 'ReDataWarehouse' database
if exists(select 1 from sys.databases where name = 'ReDataWarehouse')
begin
	alter database ReDataWarehouse set single_user with rollback immediate;
	drop database ReDataWarehouse;
end;
go

--create the 'datewarehouse' database
create database ReDataWarehouse;
go

use ReDataWarehouse ;
go

--create schemas
create schema rbronze;
go

create schema rsilver;
go

create schema rgold;
go
