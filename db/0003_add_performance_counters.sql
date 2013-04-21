DROP TABLE IF EXISTS `performance_counter`;
DROP TABLE IF EXISTS `performance_counter_value`;
DROP TABLE IF EXISTS `performance_counter_template`;
DROP TABLE IF EXISTS `performance_counter_template_item`;

CREATE TABLE `performance_counter` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) NOT NULL,
     `template_id` int(11) NOT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB;

CREATE TABLE `performance_counter_value` (
     `id` bigint NOT NULL AUTO_INCREMENT,
     `performance_counter_id` int(11) NOT NULL,
     `template_item_id` int(11) NOT NULL,
     `value` int(11) NOT NULL,
     `created` DATETIME NOT NULL,
     PRIMARY KEY (`id`),
     KEY `performance_counter_id` (`performance_counter_id`),
     KEY `created` (`created`)
) ENGINE=InnoDB;


CREATE TABLE `performance_counter_template` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `name` varchar(100) NOT NULL,
     PRIMARY KEY (`id`)
) ENGINE=InnoDB;


CREATE TABLE `performance_counter_template_item` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `template_id` int(11) NOT NULL,
     `name` varchar(100) NOT NULL,
     `check_key` varchar(255) NOT NULL,
     `unit` varchar(50) DEFAULT NULL,
     `divisor` int(11) DEFAULT 1,
     `relative` int(1) DEFAULT 0,
     PRIMARY KEY (`id`)
) ENGINE=InnoDB;

