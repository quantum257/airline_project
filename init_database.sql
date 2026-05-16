/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'airline_project' after checking if it already exists. 
    If the database exists, it is dropped and recreated. 
	
WARNING:
    Running this script will drop the entire 'airline_project' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

-- Create Databse: airline_project

use master
go

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'airline_project')
BEGIN
    DROP DATABASE airline_project;
END
go

create database airline_project

use airline_project
go 

