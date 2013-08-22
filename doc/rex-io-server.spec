Summary: Rex.IO - Middleware
Name: rex-io-server
Version: 0.2.4
Release: 1
License: Apache 2.0
Group: Utilities/System
Source: http://rex.io/downloads/rex-io-server-0.2.4.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
AutoReqProv: no

BuildRequires: rexio-perl >= 5.18.0
#Requires: libssh2 >= 1.2.8 - is included in perl-Net-SSH2 deps
Requires: rexio-perl >= 5.18.0

%description
Rex.IO is a Bare-Metal-Deployer and an infrastructure management tool.

%prep
%setup -n %{name}-%{version}


%install
%{__rm} -rf %{buildroot}
%{__mkdir} -p %{buildroot}/srv/rexio/middleware
%{__mkdir} -p %{buildroot}/etc/init.d
%{__cp} -R {bin,db,lib,t,local} %{buildroot}/srv/rexio/middleware
%{__cp} doc/rex-io-server.init %{buildroot}/etc/init.d/rex-io-server
%{__chmod} 755 %{buildroot}/etc/init.d/rex-io-server

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%pre

# create rex.io user if not there
if ! id rexio &>/dev/null; then
	groupadd -r rexio &>/dev/null
	useradd -r -d /srv/rexio -c 'Rex.IO Service User' -g rexio -m rexio &>/dev/null
fi

%post

/bin/chown -R rexio. /srv/rexio

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root, 0755)
/srv/rexio/middleware
/etc/init.d/rex-io-server

%changelog

* Thu Jul 25 2013 Jan Gehring <jan.gehring at, gmail.com> 0.2.4-1
- initial packaged

