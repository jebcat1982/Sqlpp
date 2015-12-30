--IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'$fromSchema.$fkName')
-- AND parent_object_id = OBJECT_ID(N'$fromTable'))
--ALTER TABLE $fromTable DROP CONSTRAINT [$fkName]
--GO

IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'$fromSchema.$fkName') 
AND parent_object_id = OBJECT_ID(N'$fromTable'))
ALTER TABLE $fromTable  WITH CHECK ADD  CONSTRAINT [$fkName] FOREIGN KEY($fromColumn)
REFERENCES $toTable ($toColumn)
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'$fromSchema.$fkName')
 AND parent_object_id = OBJECT_ID(N'$fromTable'))
ALTER TABLE $fromTable CHECK CONSTRAINT [$fkName]
GO


