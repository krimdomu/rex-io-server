use Rex -feature => ['0.44'];
use Rex::FS::Watch;

group dev => '172.16.120.143';

user "root";
password "box";

task "watch", sub {
  watch { directory => '.', task => 'upload', latency => 2 };
};

task "upload", group => "dev", sub {
  my $param = shift;
  my $project_dir = "/opt/rex.io/software/rex-io-server";

  for my $event (@{ $param->{changed} }) {
    print ">> $event->{relative_path} ($event->{event})\n";
    if($event->{event} eq 'deleted') {
      rm "$project_dir/$event->{relative_path}"    if($event->{type} eq 'file');
      rmdir "$project_dir/$event->{relative_path}" if($event->{type} eq 'dir');
    }
    else {
      file "$project_dir/$event->{relative_path}",
        source =>  $event->{path}                  if($event->{type} eq "file");

      mkdir "$project_dir/$event->{relative_path}" if($event->{type} eq "dir");
    }
  }

  service "rex-io-server" => "restart";
};
