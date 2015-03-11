DROP TABLE IF EXISTS `permission_set`;
DROP TABLE IF EXISTS `permission`;
DROP TABLE IF EXISTS `permission_type`;

CREATE  TABLE `permission_set` (
  `id` INT NOT NULL ,
  `name` VARCHAR(50) NULL ,
  `description` VARCHAR(255) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

CREATE  TABLE `permission` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `permission_set_id` INT NOT NULL ,
  `perm_id` INT NULL ,
  `group_id` INT NULL ,
  `user_id` INT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `permission_set_id` (`permission_set_id` ASC) )
ENGINE = InnoDB;

CREATE  TABLE `permission_type` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

INSERT INTO `permission_set` (`id`, `name`, `description`) VALUES(1, 'root', 'Default permissions');

INSERT INTO `permission_type` (`id`, `name`) VALUES(1, 'READ');
INSERT INTO `permission_type` (`id`, `name`) VALUES(2, 'MODIFY');
INSERT INTO `permission_type` (`id`, `name`) VALUES(3, 'DELETE');
INSERT INTO `permission_type` (`id`, `name`) VALUES (5, 'LIST_GROUP');
INSERT INTO `permission_type` (`id`, `name`) VALUES (6, 'CREATE_GROUP');
INSERT INTO `permission_type` (`id`, `name`) VALUES (7, 'DELETE_GROUP');
INSERT INTO `permission_type` (`id`, `name`) VALUES (8, 'MODIFY_USER');
INSERT INTO `permission_type` (`id`, `name`) VALUES (15, 'LIST_PERM_SET');
INSERT INTO `permission_type` (`id`, `name`) VALUES (16, 'LIST_PERM');
INSERT INTO `permission_type` (`id`, `name`) VALUES (17, 'CREATE_PERM_SET');
INSERT INTO `permission_type` (`id`, `name`) VALUES (18, 'CREATE_PERM');
INSERT INTO `permission_type` (`id`, `name`) VALUES (19, 'MODIFY_PERM_SET');
INSERT INTO `permission_type` (`id`, `name`) VALUES (20, 'MODIFY_PERM');
INSERT INTO `permission_type` (`id`, `name`) VALUES (21, 'DELETE_PERM_SET');
INSERT INTO `permission_type` (`id`, `name`) VALUES (22, 'DELETE_PERM');
INSERT INTO `permission_type` (`id`, `name`) VALUES (24, 'LIST_USER');
INSERT INTO `permission_type` (`id`, `name`) VALUES (25, 'CREATE_USER');
INSERT INTO `permission_type` (`id`, `name`) VALUES (26, 'DELETE_USER');
INSERT INTO `permission_type` (`id`, `name`) VALUES (27, 'MODIFY_USER');

INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 1, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 2, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 3, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 5, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 6, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 7, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 8, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 15, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 16, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 17, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 18, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 19, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 20, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 21, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 22, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 24, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 25, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 26, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 27, 1);

ALTER TABLE `hardware` ADD COLUMN (`permission_set_id` INT NOT NULL DEFAULT 1);
ALTER TABLE `users` ADD COLUMN `permission_set_id` INT NULL  AFTER `group_id` ;
