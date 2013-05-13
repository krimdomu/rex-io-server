INSERT INTO `groups` (`id`, `name`) VALUES(1, 'root');
INSERT INTO `groups` (`id`, `name`) VALUES(2, 'nobody');

ALTER TABLE `users` ADD COLUMN (`group_id` INT NOT NULL DEFAULT 2);

