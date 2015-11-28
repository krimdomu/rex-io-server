-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Fri Nov 27 11:43:59 2015
-- 

;
BEGIN TRANSACTION;
--
-- Table: groups
--
CREATE TABLE groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(150) NOT NULL
);
--
-- Table: permission_set
--
CREATE TABLE permission_set (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(150) NOT NULL,
  description text
);
--
-- Table: permission_type
--
CREATE TABLE permission_type (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(150) NOT NULL
);
--
-- Table: permission
--
CREATE TABLE permission (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  permission_set_id integer NOT NULL,
  perm_id integer NOT NULL,
  group_id integer,
  user_id integer,
  FOREIGN KEY (permission_set_id) REFERENCES permission_set(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (perm_id) REFERENCES permission_type(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX permission_idx_permission_set_id ON permission (permission_set_id);
CREATE INDEX permission_idx_perm_id ON permission (perm_id);
--
-- Table: users
--
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(150) NOT NULL,
  password varchar(255) NOT NULL,
  group_id integer NOT NULL,
  permission_set_id integer NOT NULL,
  FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (permission_set_id) REFERENCES permission_set(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX users_idx_group_id ON users (group_id);
CREATE INDEX users_idx_permission_set_id ON users (permission_set_id);
COMMIT;
