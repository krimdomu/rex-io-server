alter table network_adapter add key (network_bridge_id);
alter table bios add key (hardware_id);
alter table harddrive add key (hardware_id);
alter table hardware_task add key (hardware_id);
alter table memory add key (hardware_id);
alter table network_adapter add key (hardware_id);
alter table network_bridge add key (hardware_id);
alter table processor add key (hardware_id);

