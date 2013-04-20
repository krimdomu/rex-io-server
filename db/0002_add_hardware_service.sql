DROP TABLE IF EXISTS `hardware_service`;
DROP TABLE IF EXISTS `hardware_task`;

CREATE TABLE `hardware_task` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) DEFAULT NULL,
     `task_id` int(11) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB ;

DROP TABLE IF EXISTS `service`;
CREATE TABLE `service` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `service_name` varchar(255) DEFAULT NULL,
     PRIMARY KEY (`id`)
) ENGINE=InnoDB ;

DROP TABLE IF EXISTS `service_task`;
CREATE TABLE `service_task` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `service_id` int(11) NOT NULL,
     `task_name` varchar(255) DEFAULT NULL,
     `task_description` varchar(255) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `service_id` (`service_id`)
) ENGINE=InnoDB ;

ALTER TABLE hardware_task ADD COLUMN (`task_order` int(11) DEFAULT 0);
