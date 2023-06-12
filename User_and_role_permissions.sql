--User and role permissions
--Grant select access on database
--use the same database
GRANT SELECT ON DATABASE :: [AdventureWorksDW2017] TO test_user

--Grant dmvs access to user
USE MASTER
GO
GRANT VIEW SERVER STATE TO test_user 

--Create a new role
CREATE ROLE TEST_ROLE

--Assign the role all the access
GRANT SELECT ON DATABASE :: [AdventureWorksDW2017] TO test_role; 

--Add the user to the role
ALTER ROLE test_role ADD MEMBER test_user;

--Check user or role permissions
SELECT  name,principal_id,type,type_desc,owning_principal_id
FROM sys.database_principals
where name like '%%'

