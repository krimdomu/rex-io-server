INSERT INTO `group` (`id`, `name`) VALUES(1, 'root');
INSERT INTO `group` (`id`, `name`) VALUES(2, 'nobody');

ALTER TABLE `user` ADD COLUMN (`group_id` INT NOT NULL DEFAULT 2);

