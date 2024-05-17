--disable sqlprofile lyf6
exec dbms_sqltune.alter_sql_profile('lyf6','STATUS','DISABLED');
--enable sqlprofile lyf6
exec dbms_sqltune.alter_sql_profile('lyf6','STATUS','ENABLED');
--drop sqlprofile lyf6
exec dbms_sqltune.drop_sql_profile('lyf6');
