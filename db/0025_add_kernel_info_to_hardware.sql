ALTER TABLE `rexio_server`.`hardware`
  ADD COLUMN
    `kernelrelease` VARCHAR(100) NULL  AFTER `permission_set_id` ,
  ADD COLUMN
    `kernelversion` VARCHAR(100) NULL  AFTER `kernelrelease` ;
