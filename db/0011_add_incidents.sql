DROP TABLE IF EXISTS `incidents`;
DROP TABLE IF EXISTS `incident_status`;
DROP TABLE IF EXISTS `incident_message`;

CREATE TABLE `incidents` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `title` VARCHAR(255) NOT NULL,
     `status_id` INT(11) NOT NULL DEFAULT 1,
     `created` TIMESTAMP NOT NULL DEFAULT NOW(),
     `creator` INT NOT NULL,
     `assignee` INT NOT NULL,
     `short` TEXT,
     `content` LONGTEXT,
     PRIMARY KEY (`id`),
     KEY `status_id` (`status_id`)
) ENGINE=InnoDB;

CREATE TABLE `incident_status` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `name` VARCHAR(255) NOT NULL,
     PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE `incident_message` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `incident_id` int(11) NOT NULL,
     `title` VARCHAR(255) NOT NULL,
     `creator` INT NOT NULL,
     `created` TIMESTAMP NOT NULL DEFAULT NOW(),
     `message` LONGTEXT,
     PRIMARY KEY (`id`),
     KEY `incident_id` (`incident_id`)
) ENGINE=InnoDB;


INSERT INTO `incident_status` (`id`, `name`) VALUES(1, 'new');
INSERT INTO `incident_status` (`id`, `name`) VALUES(2, 'opened');
INSERT INTO `incident_status` (`id`, `name`) VALUES(3, 'closed');
INSERT INTO `incident_status` (`id`, `name`) VALUES(4, 'invalid');
INSERT INTO `incident_status` (`name`) VALUES('in progress');

