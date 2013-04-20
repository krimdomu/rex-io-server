DROP TABLE IF EXISTS `hardware_service`;
CREATE TABLE `hardware_service` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) DEFAULT NULL,
     `service_id` int(11) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB ;

DROP TABLE IF EXISTS `service`;
CREATE TABLE `service` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `service_name` varchar(255) DEFAULT NULL,
     `task_name` varchar(255) DEFAULT NULL,
     `task_description` varchar(255) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `service_name` (`service_name`)
) ENGINE=InnoDB ;
