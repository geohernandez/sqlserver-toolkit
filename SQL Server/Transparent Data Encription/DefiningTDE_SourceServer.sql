--====================================================================================================================================
-- The following TSQL statements allow you to configure the feature Transparent Data Encryption, it has been developed
-- for demo and can be used as a base for building an automate solution which define the main components that integrate
-- the TDE configuration, these are:
--  1. Service Master Key
--  2. Create Certificate
--  3. Create Database Encryption
--  4. Set Encryption on target DB
--  More info in the following links:
--  https://docs.microsoft.com/en-us/sql/relational-databases/security/encryption/transparent-data-encryption?view=sql-server-ver15
--  https://www.sqlshack.com/restoring-transparent-data-encryption-tde-enabled-databases-on-a-different-server/
--  https://www.sqlshack.com/how-to-monitor-and-manage-transparent-data-encryption-tde-in-sql-server/
--===================================================================================================================================

-- Creating a demo DB
CREATE DATABASE MyTestDB;
GO

USE MyTestDB;
GO

--// It is fundamental to generate the main objects under master database // --
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AgreatPassword!';
GO
CREATE CERTIFICATE MyServerCert
WITH SUBJECT = 'My DEK Certificate';
GO

--Inmediatly that you have created the Certificate, you must backup the certificate and the private key files
--Keep save the Password used because when you want to restore the Certificate you must setup it.

BACKUP CERTIFICATE MyServerCert TO FILE = '/var/opt/mssql/data/MyServerCert.cer'
WITH PRIVATE KEY
(
    FILE = '/var/opt/mssql/data/MyServerCert.pvk',
    ENCRYPTION BY PASSWORD = 'AgreatPassword!Backup'
);
GO

--You can use the Algorithm property equal to ALGORITHM = AES_256 and need to put in use your target DB
--It is mandatory to put in use the DB that you want to encrypt and define the Algorithm and Server Certificate
USE MyTestDB;
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO


--Enable encryption on the database.  It is so important to monitoring the process, it could take several times
--which depend of the DB size
ALTER DATABASE MyTestDB SET ENCRYPTION ON;
GO

-- Query to verify the symmetric keys
SELECT [name],
       [principal_id],
       [algorithm_desc],
       [create_date]
FROM master.sys.symmetric_keys;

-- Query to check the status of the DB respect to the encryption
SELECT DB_NAME(database_id) AS DatabaseName,
       encryption_state,
       encryption_state_desc = CASE encryption_state
                                   WHEN '0' THEN
                                       'No database encryption key present, no encryption'
                                   WHEN '1' THEN
                                       'Unencrypted'
                                   WHEN '2' THEN
                                       'Encryption in progress'
                                   WHEN '3' THEN
                                       'Encrypted'
                                   WHEN '4' THEN
                                       'Key change in progress'
                                   WHEN '5' THEN
                                       'Decryption in progress'
                                   WHEN '6' THEN
                                       'Protection change in progress (The certificate or asymetric key that is encrypting the database encrypted'
                                   ELSE
                                       'No Status'
                               END,
       percent_complete,
       encryptor_thumbprint,
       encryptor_type
FROM sys.dm_database_encryption_keys;

-- After you have verified that everything is Ok, you should do a Backup of your DB, move this backup to the target Server, try to restore and 
-- verify that it does not work until you restore the certificate