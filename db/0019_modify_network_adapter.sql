alter table network_adapter modify column virtual int(2) default 0;
update network_adapter set virtual=0 where virtual is null;

alter table network_adapter modify column boot int(2) default 0;
update network_adapter set boot=0 where boot is null;
