DROP TABLE IF EXISTS `queued_jobs`;

CREATE TABLE `queued_jobs` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) DEFAULT NULL,
     `task_id` int(11) DEFAULT NULL,
     `task_order` int(11) DEFAULT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;

