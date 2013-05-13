ALTER TABLE `hardware` CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incidents` CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incident_message` CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incident_status` CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `performance_counter_template` CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `performance_counter_template_item` CHARACTER SET utf8 COLLATE utf8_general_ci;

ALTER TABLE `incidents` MODIFY `title` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incidents` MODIFY `content` LONGTEXT CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incident_status` MODIFY `name` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incident_message` MODIFY `title` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `incident_message` MODIFY `message` LONGTEXT CHARACTER SET utf8 COLLATE utf8_general_ci;


ALTER TABLE `hardware` MODIFY `name` VARCHAR(150) CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `hardware` MODIFY `uuid` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci;

ALTER TABLE `performance_counter_template` MODIFY `name` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE `performance_counter_template_item` MODIFY `name` VARCHAR(100) CHARACTER SET utf8 COLLATE utf8_general_ci;



