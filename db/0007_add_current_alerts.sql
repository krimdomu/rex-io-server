DROP TABLE IF EXISTS `current_alerts`;

CREATE TABLE `current_alerts` (
     `id` int(11) NOT NULL AUTO_INCREMENT,
     `hardware_id` int(11) NOT NULL,
     `template_item_id` int(11) NOT NULL,
     `created` int(11) NOT NULL,
     PRIMARY KEY (`id`),
     KEY `hardware_id` (`hardware_id`),
     KEY `template_item_id` (`template_item_id`),
     KEY `created` (`created`)
) ENGINE=InnoDB CHARACTER SET utf8;

