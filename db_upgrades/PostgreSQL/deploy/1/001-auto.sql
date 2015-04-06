-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Mon Apr  6 19:42:16 2015
-- 
;
--
-- Table: groups.
--
CREATE TABLE "groups" (
  "id" serial NOT NULL,
  "name" character varying(150) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: permission_set.
--
CREATE TABLE "permission_set" (
  "id" serial NOT NULL,
  "name" character varying(150) NOT NULL,
  "description" text,
  PRIMARY KEY ("id")
);

;
--
-- Table: permission_type.
--
CREATE TABLE "permission_type" (
  "id" serial NOT NULL,
  "name" character varying(150) NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: permission.
--
CREATE TABLE "permission" (
  "id" serial NOT NULL,
  "permission_set_id" integer NOT NULL,
  "perm_id" integer NOT NULL,
  "group_id" integer,
  "user_id" integer,
  PRIMARY KEY ("id")
);
CREATE INDEX "permission_idx_permission_set_id" on "permission" ("permission_set_id");
CREATE INDEX "permission_idx_perm_id" on "permission" ("perm_id");

;
--
-- Table: users.
--
CREATE TABLE "users" (
  "id" serial NOT NULL,
  "name" character varying(150) NOT NULL,
  "password" character varying(255) NOT NULL,
  "group_id" integer NOT NULL,
  "permission_set_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "users_idx_group_id" on "users" ("group_id");
CREATE INDEX "users_idx_permission_set_id" on "users" ("permission_set_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "permission" ADD CONSTRAINT "permission_fk_permission_set_id" FOREIGN KEY ("permission_set_id")
  REFERENCES "permission_set" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "permission" ADD CONSTRAINT "permission_fk_perm_id" FOREIGN KEY ("perm_id")
  REFERENCES "permission_type" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "groups" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_permission_set_id" FOREIGN KEY ("permission_set_id")
  REFERENCES "permission_set" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
