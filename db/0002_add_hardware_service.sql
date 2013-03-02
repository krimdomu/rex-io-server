CREATE TABLE `hardware_service` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) DEFAULT NULL,
     `service_name` varchar(255) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB ;
