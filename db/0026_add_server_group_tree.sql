DROP TABLE IF EXISTS `server_group_tree`;
CREATE  TABLE `server_group_tree` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `root_id` INT NULL ,
  `lft` INT NOT NULL ,
  `rgt` INT NOT NULL ,
  `level` INT NOT NULL ,
  `permission_set_id` INT NOT NULL DEFAULT 1 ,
  `name` VARCHAR(100) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `lft` (`lft` ASC) ,
  INDEX `rgt` (`rgt` ASC) ,
  INDEX `level` (`level` ASC) ,
  INDEX `permission_set_id` (`permission_set_id` ASC) );
