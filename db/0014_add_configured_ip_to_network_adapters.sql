ALTER TABLE network_adapter ADD COLUMN (wanted_ip BIGINT);
ALTER TABLE network_adapter ADD COLUMN (wanted_netmask BIGINT);
ALTER TABLE network_adapter ADD COLUMN (wanted_network BIGINT);
ALTER TABLE network_adapter ADD COLUMN (wanted_gateway BIGINT);
ALTER TABLE network_adapter ADD COLUMN (wanted_broadcast BIGINT);

