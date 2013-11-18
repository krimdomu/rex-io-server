-- alter table hardware modify column os_template_id int default 1;
-- alter table hardware modify column os_id int default 1;
-- alter table hardware modify column server_group_id int default 1;
-- update hardware set os_template_id=1 where os_template_id is null;
-- update hardware set os_id=1 where os_id is null;

-- fix relations
-- update hardware set server_group_id=1;
