--
-- (c)2026 Ira Parsons
-- init.sql - initialize contents of coblsky database
--

CREATE TABLE BLOBS
 (CID CHAR(25) NOT NULL,
  VAL BLOB             ,
  PRIMARY KEY(CID)     );