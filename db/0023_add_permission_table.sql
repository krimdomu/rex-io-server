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
INSERT INTO `permission_type` (`id`, `name`) VALUES(4, 'CREATE_HARDWARE');

INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 1, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 2, 1);
INSERT INTO `permission` (`permission_set_id`, `perm_id`, `user_id`) VALUES(1, 3, 1);
INSERT INTO `permission` (`permission_set_id`, `user_id`, `perm_id`) VALUES (1, 1, 4);


ALTER TABLE `hardware` ADD COLUMN (`permission_set_id` INT NOT NULL DEFAULT 1);
ALTER TABLE `users` ADD COLUMN `permission_set_id` INT NULL  AFTER `group_id` ;
