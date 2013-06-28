DROP TABLE IF EXISTS `dc_locations`;
CREATE TABLE `dc_locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT NOW(),
  `info` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8;

