DROP TABLE IF EXISTS `dc_rows`;
CREATE TABLE `dc_rows` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `location_id` int(11) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT NOW(),
  `info` TEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8;

