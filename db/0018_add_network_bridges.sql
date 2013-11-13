DROP TABLE IF EXISTS `network_bridge`;

CREATE TABLE `network_bridge` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) DEFAULT NULL,
     `name` varchar(50) DEFAULT NULL,
     `spanning_tree` int(2) DEFAULT 0,
     `wait_port` int(2) DEFAULT 0,
     `forwarding_delay` int(2) DEFAULT 0,
     `ip` int(11) DEFAULT NULL,
     `netmask` int(11) DEFAULT NULL,
     `broadcast` int(11) DEFAULT NULL,
     `network` int(11) DEFAULT NULL,
     `gateway` int(11) DEFAULT NULL,
     `proto` varchar(50) DEFAULT 'static',
     `boot` int(2) DEFAULT 0,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;

ALTER TABLE `network_adapter` ADD COLUMN `network_bridge_id` int(11) DEFAULT NULL;


