DROP TABLE IF EXISTS `server_groups`;

CREATE TABLE `server_groups` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `parent_id` INTEGER NOT NULL DEFAULT 0,
     `name` VARCHAR(255) NOT NULL DEFAULT "unnamed",
     `description` TEXT,
     `created` TIMESTAMP NOT NULL DEFAULT NOW(),
     PRIMARY KEY (`id`),
     KEY `parent_id` (`parent_id`)
) ENGINE=InnoDB CHARACTER SET utf8;

