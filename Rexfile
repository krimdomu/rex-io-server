#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
# vim: set ft=perl:

use Rex -feature => ['1.0', 'no_path_cleanup'];
use Rex::Ext::ParamLookup;
use Rex::Lang::Perl::Carton;

task "setup", sub {

  my $db_server   = param_lookup "db_server", "127.0.0.1";
  my $db_schema   = param_lookup "db_schema", "rexio";
  my $db_username = param_lookup "db_username", "rexio";
  my $db_password = param_lookup "db_password", "rexio";

  my $auth_salt = param_lookup "auth_salt", get_random(16, 'a' .. 'z');
  
  my $log_file = param_lookup "log_file", "log/server.log";

  file "server.conf",
    content => template('@server.conf.tpl'),
    mode    => '0640';

  carton "-install";
  
  for my $cmd (
    'bin/database.pl --cmd install',
    'bin/rex_io_add_permission_type server.conf root',
    'bin/rex_io_add_permission_set server.conf root',
    'bin/rex_io_add_group server.conf root',
    'bin/rex_io_add_user server.conf root passw0rd root root',
    'bin/rex_io_add_permission server.conf root root root',
  ) {
    say "Running: $cmd";
    carton -exec => $cmd;
  }

};

task "upgrade", sub {
  carton -exec => "bin/database.pl --cmd upgrade";
};

1;


__DATA__

@server.conf.tpl
{
   # plugins that should be loaded
   plugins => [
      # basic plugins
      "User",
      "Group",
      "Permission",
   ],

   # database configuration
   # currently only mysql is supported
   database => {
      host     => "<%= $db_server %>",
      schema   => "<%= $db_schema %>",
      username => "<%= $db_username %>",
      password => "<%= $db_password %>",
   },

   # see https://metacpan.org/module/Digest::Bcrypt for more information
   auth => {
      salt => '<%= $auth_salt %>', # 16 bytes long
      cost => 1, # between 1 and 31
   },

   # session settings
   session => {
      key => 'Rex.IO.Server',
   },

   log => {
      file => "<%= $log_file %>",
      level => "debug",
   },
}
@end
