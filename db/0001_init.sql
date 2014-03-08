-- MySQL dump 10.13  Distrib 5.1.66, for apple-darwin11.4.2 (i386)
--
-- Host: localhost    Database: rexio_server
-- ------------------------------------------------------
-- Server version	5.1.66

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `bios`
--

DROP TABLE IF EXISTS `bios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bios` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hardware_id` int(11) DEFAULT NULL,
  `biosdate` datetime DEFAULT NULL,
  `version` varchar(50) DEFAULT NULL,
  `ssn` varchar(150) DEFAULT NULL,
  `manufacturer` varchar(150) DEFAULT NULL,
  `model` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `bios`
--

LOCK TABLES `bios` WRITE;
/*!40000 ALTER TABLE `bios` DISABLE KEYS */;
/*!40000 ALTER TABLE `bios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `groups`
--

DROP TABLE IF EXISTS `groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `groups`
--

LOCK TABLES `groups` WRITE;
/*!40000 ALTER TABLE `groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `harddrive`
--

DROP TABLE IF EXISTS `harddrive`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `harddrive` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hardware_id` int(11) DEFAULT NULL,
  `devname` varchar(50) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `vendor` varchar(150) DEFAULT NULL,
  `serial` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `harddrive`
--

LOCK TABLES `harddrive` WRITE;
/*!40000 ALTER TABLE `harddrive` DISABLE KEYS */;
/*!40000 ALTER TABLE `harddrive` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hardware`
--

DROP TABLE IF EXISTS `hardware`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hardware` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `state_id` int(2) DEFAULT '1',
  `os_template_id` int(11) DEFAULT NULL,
  `os_id` int(11) DEFAULT NULL,
  `uuid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hardware`
--

LOCK TABLES `hardware` WRITE;
/*!40000 ALTER TABLE `hardware` DISABLE KEYS */;
/*!40000 ALTER TABLE `hardware` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hardware_state`
--

DROP TABLE IF EXISTS `hardware_state`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hardware_state` (
  `id` int(2) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 AUTO_INCREMENT=5 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hardware_state`
--

LOCK TABLES `hardware_state` WRITE;
/*!40000 ALTER TABLE `hardware_state` DISABLE KEYS */;
INSERT INTO `hardware_state` VALUES (1,'UNKNOWN'),(2,'INSTALLING'),(3,'INSTALLING'),(4,'INSTALLED');
/*!40000 ALTER TABLE `hardware_state` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `memory`
--

DROP TABLE IF EXISTS `memory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `memory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hardware_id` int(11) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `bank` int(11) DEFAULT NULL,
  `serialnumber` varchar(255) DEFAULT NULL,
  `speed` varchar(50) DEFAULT NULL,
  `type` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `memory`
--

LOCK TABLES `memory` WRITE;
/*!40000 ALTER TABLE `memory` DISABLE KEYS */;
/*!40000 ALTER TABLE `memory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `network_adapter`
--

DROP TABLE IF EXISTS `network_adapter`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `network_adapter` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hardware_id` int(11) NOT NULL,
  `dev` varchar(50) NOT NULL DEFAULT 'eth0',
  `proto` varchar(50) NOT NULL DEFAULT 'dhcp',
  `ip` bigint(20) DEFAULT NULL,
  `netmask` bigint(20) DEFAULT NULL,
  `broadcast` bigint(20) DEFAULT NULL,
  `network` bigint(20) DEFAULT NULL,
  `gateway` bigint(20) DEFAULT NULL,
  `mac` varchar(50) DEFAULT NULL,
  `boot` int(2) DEFAULT NULL,
  `virtual` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `network_adapter`
--

LOCK TABLES `network_adapter` WRITE;
/*!40000 ALTER TABLE `network_adapter` DISABLE KEYS */;
/*!40000 ALTER TABLE `network_adapter` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `os`
--

DROP TABLE IF EXISTS `os`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `os` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `version` varchar(20) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 AUTO_INCREMENT=8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `os`
--

LOCK TABLES `os` WRITE;
/*!40000 ALTER TABLE `os` DISABLE KEYS */;
INSERT INTO `os` VALUES (1,'12.04','Ubuntu'),(5,'15','Fedora'),(4,'16','Fedora'),(3,'11.04','Ubuntu'),(2,'11.10','Ubuntu'),(6,'10.7.5','Mac OS X'),(7,'6.0.3','Debian');
/*!40000 ALTER TABLE `os` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `os_template`
--

DROP TABLE IF EXISTS `os_template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `os_template` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `kernel` varchar(255) DEFAULT NULL,
  `initrd` varchar(255) DEFAULT NULL,
  `append` text,
  `template` text,
  `ipxe` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 AUTO_INCREMENT=5 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `os_template`
--

LOCK TABLES `os_template` WRITE;
/*!40000 ALTER TABLE `os_template` DISABLE KEYS */;
-- INSERT INTO `os_template` VALUES (3,'Ubuntu 12.04 (64bit)','http://192.168.7.1/ubuntu-installer/amd64/linux','http://192.168.7.1/ubuntu-installer/amd64/initrd.gz','pkgsel/language-pack-patterns= pkgsel/install-language-support=false vga=normal locale=en_US setup/layoutcode=en_US console-setup/layoutcode=us keyboard-configuration/layoutcode=us netcfg/wireless_wep= netcfg/choose_interface=%eth preseed/url=http://192.168.1.4:3000/deploy/boot netcfg/get_hostname=%hostname --','# some basic stuff\nd-i     debian-installer/locale string en_US.UTF-8\nd-i     debian-installer/splash boolean false\nd-i     console-setup/ask_detect        boolean false\nd-i     console-setup/layoutcode        string us\nd-i     console-setup/variantcode       string \n# mirror settings\nd-i	mirror/country string manual\nd-i	mirror/http/hostname string 192.168.1.6\nd-i	mirror/http/directory string /ubuntu\nd-i	mirror/http/proxy string\n# network setttings\nd-i     netcfg/get_nameservers  string \nd-i     netcfg/get_ipaddress    string \nd-i     netcfg/get_netmask      string 255.255.255.0\nd-i     netcfg/get_gateway      string \nd-i     netcfg/confirm_static   boolean true\nd-i     netcfg/get_hostname     string <%= $hardware->name %>\n# time settings\nd-i     time/zone string Europe/Berlin\nd-i     clock-setup/utc boolean true\nd-i     clock-setup/utc boolean true\nd-i     clock-setup/ntp boolean false\nd-i     clock-setup/ntp-server  string pool.ntp.org\n# Partition setup\nd-i     partman-auto/method string regular\nd-i     partman-lvm/device_remove_lvm boolean true\nd-i     partman-lvm/confirm boolean true\nd-i     partman/confirm_write_new_label boolean true\nd-i     partman/choose_partition        select Finish partitioning and write changes to disk\nd-i     partman/confirm boolean true\nd-i     partman/confirm_nooverwrite boolean true\nd-i     partman/default_filesystem string ext4\n\nd-i     base-installer/kernel/image     string linux-server\nd-i     passwd/root-login       boolean false\nd-i     passwd/make-user        boolean true\nd-i     passwd/user-fullname    string ubuntu\nd-i     passwd/username string ubuntu\nd-i     passwd/user-password-crypted    password test\nd-i     passwd/user-uid string \nd-i     user-setup/allow-password-weak  boolean true\nd-i     user-setup/encrypt-home boolean false\nd-i     passwd/user-default-groups      string adm cdrom dialout lpadmin plugdev sambashare\nd-i     apt-setup/services-select       multiselect security\nd-i     apt-setup/security_host string 192.168.1.6\nd-i     apt-setup/security_path string /ubuntu-security\nd-i     debian-installer/allow_unauthenticated  string false\ntasksel tasksel/first multiselect openssh-server\nd-i     pkgsel/upgrade  select safe-upgrade\nd-i     pkgsel/language-packs   multiselect \nd-i     pkgsel/update-policy    select none\nd-i     pkgsel/updatedb boolean true\nd-i     grub-installer/skip     boolean false\nd-i     lilo-installer/skip     boolean false\nd-i     grub-installer/only_debian      boolean true\nd-i     grub-installer/with_other_os    boolean true\nd-i     finish-install/keep-consoles    boolean false\nd-i     finish-install/reboot_in_progress       note \nd-i     cdrom-detect/eject      boolean true\nd-i     debian-installer/exit/halt      boolean false\nd-i     debian-installer/exit/poweroff  boolean false\n# Which extra packages should be installed \nd-i     pkgsel/include string openssh-server vim bridge-utils\n# Post run (custom stuff)\nd-i    preseed/late_command string in-target wget http://192.168.1.4:3000/deploy/boot;\n','');

-- INSERT INTO `os_template` VALUES (4,'Centos 6.4 (64bit)','http://192.168.7.1/boot/centos/6.4/x86_64/vmlinuz','http://192.168.7.1/boot/centos/6.4/x86_64/initrd.img','ks=http://192.168.7.1:5000/deploy/boot?kickstart=1 ramdisk_size=100000 ksdevice=%eth','# start the installation process\ninstall\n\n# configure a connection to a FTP server to locate installation files\nurl --url http://192.168.7.1/linux/centos/6.4/os/x86_64/\n\n# setup language and keyboard\nlang en_US.UTF-8\nkeyboard de\n\n# set networkinformation from configuration\n% my @devs = $hardware->network_adapters;\n% for my $dev (@devs) {\n% next if($dev->dev eq "lo");\n   % if ($dev->proto eq "dhcp") {\nnetwork --device <%= $dev->dev %> bootproto dhcp --onboot=on --noipv6 --hostname=<%= $hardware->name %>\n   % } else {\nnetwork --device <%= $dev->dev %> bootproto static <% if($dev->gateway) { %> --gateway=<%= int_to_ip($dev->gateway) %> <% } %> --ip=<%= int_to_ip($dev->ip) %> --netmask=<%= int_to_ip($dev->netmask) %> --onboot=on --nameserver=192.168.7.1 --noipv6 --hostname=<%= $hardware->name %>\n   % }\n% }\n\n# setup encrypted root password, you can take out the encrypted password from /etc/shadow file\n# this password is "test"\nrootpw --iscrypted $6$XuOKLG5O$TZW/1lLQ5fy56Hj7AjLg4fwta.oL4DGSdCHANI4Ty5gaH23tgWxgq8erWoyRxbfatK26GWnmCNh48wn5scrC10\n\n# setup firewall and open ssh port 22\nfirewall --service=ssh\n\n# shadow auth\nauthconfig --enableshadow\n\n# The selinux directive can be set to --enforcing, --permissive, or --disabled\n# disable selinux\nselinux --disabled\n\n# setup timezone\ntimezone Europe/Berlin\n\n# write bootloader to mbr\nbootloader --location=mbr --driveorder=vda --append="crashkernel=auto rhgb quiet"\n\n# Clear the Master Boot Record\nzerombr yes\n\n# This directive clears all volumes on the sda hard drive.\nclearpart --all --drives=vda --initlabel\n\n# Changes are required in the partition (part) directives that follow.\npart /boot --fstype=ext4 --size=500\npart / --fstype=ext4 --size=5000\npart /var --fstype=ext4 --size=10000\npart swap --size=1000\n\n#reboot machine\nreboot\n\n#skip answers to the First Boot process\nfirstboot --disable\n\n# if you want to use a % you have to write %%\n%%packages\n@base\n@core\n@perl-runtime\nopenssh-server\nopenssh-clients\n%%end\n\n%%post\nwget http://192.168.7.1:5000/deploy/boot?finished=true\n','');

INSERT INTO `os_template` VALUES (1,'Local','','','','','#!ipxe\nsanboot --no-describe --drive 0x80');

-- INSERT INTO `os_template` VALUES (2,'Inventory','http://{{REXIO_SERVER}}/boot/rexio/vmlinuz','http://{{REXIO_SERVER}}/boot/rexio/initrd.img','REXIO_SERVER={{REXIO_SERVER}}:{{REXIO_SERVER_PORT}} boot=live fetch=http://{{REXIO_SERVER}}/boot/rexio/rexio.squashfs noeject ssh=test lang=de vga=791','','');

/*!40000 ALTER TABLE `os_template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `processor`
--

DROP TABLE IF EXISTS `processor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `processor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hardware_id` int(11) DEFAULT NULL,
  `modelname` varchar(150) DEFAULT NULL,
  `vendor` varchar(150) DEFAULT NULL,
  `flags` varchar(150) DEFAULT NULL,
  `mhz` int(11) DEFAULT NULL,
  `cache` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `processor`
--

LOCK TABLES `processor` WRITE;
/*!40000 ALTER TABLE `processor` DISABLE KEYS */;
/*!40000 ALTER TABLE `processor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_group`
--

DROP TABLE IF EXISTS `user_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `user_group` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `group_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`,`group_id`)
) ENGINE=InnoDB CHARACTER SET utf8 ;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_group`
--

LOCK TABLES `user_group` WRITE;
/*!40000 ALTER TABLE `user_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_group` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-02-10 12:51:52
