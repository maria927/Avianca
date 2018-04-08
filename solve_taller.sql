/*
2. Create 2 Tablespaces (0.125)?:
    a. first one with 2 Gb and 1 datafile, tablespace should be named "avianca"?
    b. Undo tablespace with 25Mb of space and 1 datafile*/
    
   /*a*/ CREATE TABLESPACE avianca DATAFILE 
    'avianca101.dbf' SIZE 2G
    SEGMENT SPACE MANAGEMENT AUTO
    ONLINE;
    
    /*b*/ CREATE UNDO TABLESPACE undospace
   DATAFILE 'undotbs_1a.dbf'
   SIZE 25M AUTOEXTEND ON
   RETENTION GUARANTEE;
    
/*3. Set the undo tablespace to be used in the system (0.125)*/



/*4. Create a DBA user (with the role DBA) and assign it to the tablespace called "avianca?", this user has
unlimited space on the tablespace (The user should have permission to connect) (0.125)*/

CREATE USER DBA_USER 
IDENTIFIED BY dba_user
DEFAULT TABLESPACE avianca 
QUOTA UNLIMITED  ON avianca;

GRANT DBA TO DBA_USER;
GRANT CONNECT TO DBA_USER;

/*5. Create 2 profiles. (0.125)
    a. Profile 1: "clerk" password life 40 days, one session per user, 10 minutes idle, 4 failed login
    attempts*/
    
CREATE PROFILE clerk LIMIT
PASSWORD_LIFE_TIME 40
SESSIONS_PER_USER 1
IDLE_TIME 10
FAILED_LOGIN_ATTEMPTS 4;
    
   /* b. Profile 2: "development" password life 100 days, two session per user, 30 minutes idle, no
    failed login attempts*/
    
CREATE PROFILE development LIMIT
PASSWORD_LIFE_TIME 100
SESSIONS_PER_USER 2
IDLE_TIME 30;
    
 
/*6. Create 4 users, assign them the tablespace "avianca?"; 2 of them should have the clerk profile and the
remaining the development profile, all the users should be allow to connect to the database. (0.125)*/

CREATE USER USER1 
IDENTIFIED BY DBA_USER
DEFAULT TABLESPACE avianca 
QUOTA UNLIMITED  ON avianca
PROFILE clerk;

CREATE USER USER2 
IDENTIFIED BY DBA_USER
DEFAULT TABLESPACE avianca 
QUOTA UNLIMITED  ON avianca
PROFILE clerk;

CREATE USER USER3 
IDENTIFIED BY DBA_USER
DEFAULT TABLESPACE avianca 
QUOTA UNLIMITED  ON avianca
PROFILE development;

CREATE USER USER4 
IDENTIFIED BY DBA_USER
DEFAULT TABLESPACE avianca 
QUOTA UNLIMITED  ON avianca
PROFILE development;

GRANT CONNECT TO USER1;
GRANT CONNECT TO USER2;
GRANT CONNECT TO USER3;
GRANT CONNECT TO USER4;

/*7. Lock one user associate with clerk profile (0.125)*/

ALTER USER USER2 ACCOUNT LOCK;


