-- Schema 

IF NOT EXISTS (SELECT 1 FROM SYS.schemas WHERE name = 'Dim')
Begin 
	Exec('CREATE SCHEMA Dim');
END;

GO

IF NOT EXISTS (SELECT 1 FROM SYS.schemas WHERE name = 'Fact')
Begin 
	Exec('CREATE SCHEMA Fact');
END;

GO