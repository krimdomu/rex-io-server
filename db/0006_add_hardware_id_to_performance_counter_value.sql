ALTER TABLE performance_counter_value ADD COLUMN (hardware_id int);
ALTER TABLE performance_counter_value ADD INDEX(performance_counter_id);
ALTER TABLE performance_counter_value ADD INDEX(hardware_id);
ALTER TABLE performance_counter_value ADD INDEX(created);
ALTER TABLE performance_counter_template_item ADD INDEX(check_key);
