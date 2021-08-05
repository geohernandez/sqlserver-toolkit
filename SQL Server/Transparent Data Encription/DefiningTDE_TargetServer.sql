--Create master key first, it should be the same used into the source SQL Instance, but it is not mandatory

USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'AgreatPassword!';
GO


-- Restore it into the targetl, the name can be whatever that you want, but the password must be the same used during the creation
-- of the Certificate Backup 
USE master;
GO
CREATE CERTIFICATE MyServerCert
FROM FILE = '/var/opt/mssql/data/MyServerCert.cer'
WITH PRIVATE KEY
(
    FILE = '/var/opt/mssql/data/MyServerCert.pvk',
    DECRYPTION BY PASSWORD = 'AgreatPassword!Backup'
);
GO

--Try to restore the backup which was made in the source DB Server and verify that the Certificate works correctly

SELECT DB_NAME(database_id) AS DatabaseName, encryption_state,
encryption_state_desc =
CASE encryption_state
  WHEN '0' THEN 'No database encryption key present, no encryption'
  WHEN '1' THEN 'Unencrypted'
  WHEN '2' THEN 'Encryption in progress'
  WHEN '3' THEN 'Encrypted'
  WHEN '4' THEN 'Key change in progress'
  WHEN '5' THEN 'Decryption in progress'
  WHEN '6' THEN 'Protection change in progress (The certificate or asymetric key that is encrypting the database encrypted'
  ELSE 'No Status'
  END,
percent_complete,encryptor_thumbprint,encryptor_type
FROM sys.dm_database_encryption_keys;
  