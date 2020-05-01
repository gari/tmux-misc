%define libeventmaj  2.1
%define libeventver  %{libeventmaj}.11
%define libeventdir  libevent-%{libeventver}-stable
%define libeventfile %{libeventdir}.tar.gz

Name:           tmux
Version:        3.1
Release:        0%{?dist}
Summary:        A terminal multiplexer

Group:          Applications/System
# Most of the source is ISC licensed; some of the files in compat/ are 2 and
# 3 clause BSD licensed.
License:        ISC and BSD
URL:            https://tmux.github.io/
Source0:        https://github.com/%{name}/%{name}/releases/download/%{version}/%{name}-%{version}.tar.gz
Source1:        https://github.com/libevent/libevent/releases/download/release-%{libeventver}-stable/%{libeventfile}
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires:  glibc-static
BuildRequires:  libevent-devel
BuildRequires:  ncurses-devel
BuildRequires:  ncurses-static
BuildRequires:  openssl-devel
BuildRequires:  openssl-static
BuildRequires:  pkgconfig

%description
tmux is a "terminal multiplexer."  It enables a number of terminals (or
windows) to be accessed and controlled from a single terminal.  tmux is
intended to be a simple, modern, BSD-licensed alternative to programs such
as GNU Screen.

%prep
%setup -q

%build
# build a static libevent
tar -zxvf %{SOURCE1}
cd %{libeventdir}
./configure --enable-static --enable-static=yes --disable-shared --enable-shared=no --prefix=`pwd`-built
make %{?_smp_mflags} LDFLAGS="%{optflags}"
make install
cd ..
LIBEVENT_PKG_CONFIG_PATH="$(find ${PWD}/%{libeventdir}-built/ -name \*.pc -exec dirname {} \; | sort -u | head -1)"
#echo $LIBEVENT_PKG_CONFIG_PATH
LIBEVENT_CFLAGS="$(env PKG_CONFIG_PATH=${LIBEVENT_PKG_CONFIG_PATH} pkg-config --cflags libevent)"
LIBEVENT_LIBS="$(env PKG_CONFIG_PATH=${LIBEVENT_PKG_CONFIG_PATH} pkg-config --libs libevent)"
#echo $LIBEVENT_CFLAGS
#echo $LIBEVENT_LIBS
%configure LIBEVENT_CFLAGS="${LIBEVENT_CFLAGS}" LIBEVENT_LIBS="${LIBEVENT_LIBS}"
make %{?_smp_mflags} LDFLAGS="%{optflags}"
echo "empty" > NOTES

%install
rm -rf %{buildroot}
make install DESTDIR=%{buildroot} INSTALLBIN="install -p -m 755" INSTALLMAN="install -p -m 644"

%clean
rm -rf %{buildroot}

%post
if [ ! -f %{_sysconfdir}/shells ] ; then
    echo "%{_bindir}/tmux" > %{_sysconfdir}/shells
else
    grep -q "^%{_bindir}/tmux$" %{_sysconfdir}/shells || echo "%{_bindir}/tmux" >> %{_sysconfdir}/shells
fi

%postun
if [ $1 -eq 0 ] && [ -f %{_sysconfdir}/shells ]; then
    sed -i '\!^%{_bindir}/tmux$!d' %{_sysconfdir}/shells
fi

%files
%defattr(-,root,root,-)
%doc CHANGES NOTES example_tmux.conf
%{_bindir}/tmux
%{_mandir}/man1/tmux.1.*

%changelog
* Thu Apr 30 2020 ryan woodsmall <rwoodsmall@gmail.com>
- tmux 3.1

* Tue Dec  3 2019 ryan woodsmall <rwoodsmall@gmail.com>
- tmux 3.0a
- libevent 2.1.11

* Thu May  2 2019 ryan woodsmall <rwoodsmall@gmail.com> - 2.9a-0
- tmux 2.9a

* Thu May  2 2019 ryan woodsmall <rwoodsmall@gmail.com> - 2.9-0
- tmux 2.9

* Wed Oct 17 2018 ryan woodsmall <rwoodsmall@gmail.com> - 2.8-0
- tmux 2.8
- fix libevent source url

* Fri Apr 20 2018 ryan woodsmall <rwoodsmall@gmail.com> - 2.7-0
- tmux 2.7

* Tue Oct 10 2017 ryan woodsmall <rwoodsmall@gmail.com> - 2.6-0
- tmux 2.6

* Tue May 30 2017 ryan woodsmall <rwoodsmall@gmail.com> - 2.5-0
- tmux 2.5

* Tue May  2 2017 ryan woodsmall <rwoodsmall@gmail.com> - 2.4-0
- tmux 2.4

* Thu Feb 16 2017 ryan woodsmall <rwoodsmall@gmail.com> - 2.3-3
- libevent lives on github now

* Fri Feb 10 2017 ryan woodsmall <rwoodsmall@gmail.com> - 2.3-2
- libevent 2.1.8 stable

* Mon Oct 10 2016 ryan woodsmall <rwoodsmall@gmail.com> - 2.3-1
- tmux 2.3

* Tue May 03 2016 ryan woodsmall <rwoodsmall@gmail.com> - 2.2-1
- tmux 2.2
- no more examples/ directory, specify example_tmux.conf as doc

* Tue Nov 10 2015 ryan woodsmall <rwoodsmall@gmail.com> - 2.1-1
- tmux 2.1 update
- tmux url updates for github

* Thu May 14 2015 ryan woodsmall <rwoodsmall@gmail.com> - 2.0-1
- include a static build of libevent 2.0.x stable
- build tmux 2.0 against custom libevent

* Fri Aug 09 2013 Steven Roberts <strobert@strobe.net> - 1.6-3
- Building for el6
- Remove tmux from the shells file upon package removal (RH bug #972633)

* Sat Jul 21 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.6-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Tue Jan 31 2012 Sven Lankes <sven@lank.es> 1.6-1
- New upstream release

* Sat Jan 14 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.5-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_17_Mass_Rebuild

* Tue Nov 01 2011 Sven Lankes <sven@lank.es> 1.5-1
- New upstream release
- Do the right thing (tm) and revert to $upstream-behaviour: 
   No longer install tmux setgid and no longer use /var/run/tmux 
   for sockets. Use "tmux -S /var/run/tmux/tmux-`id -u`/default attach"
   if you need to access an "old" tmux session
- tmux can be used as a login shell so add it to /etc/shells

* Sat Apr 16 2011 Sven Lankes <sven@lank.es> 1.4-4
- Add /var/run/tmp to tmpdir.d - fixes rhbz 656704 and 697134

* Sun Apr 10 2011 Sven Lankes <sven@lank.es> 1.4-3
- Fix CVE-2011-1496
- Fixes rhbz #693824

* Wed Feb 09 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.4-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Tue Dec 28 2010 Filipe Rosset <rosset.filipe@gmail.com> 1.4-1
- New upstream release

* Fri Aug 06 2010 Filipe Rosset <filiperosset@fedoraproject.org> 1.3-2
- Rebuild for F-13

* Mon Jul 19 2010 Sven Lankes <sven@lank.es> 1.3-1
- New upstream release

* Sun Mar 28 2010 Sven Lankes <sven@lank.es> 1.2-1
- New upstream release
- rediff writehard patch

* Mon Nov 09 2009 Sven Lankes <sven@lank.es> 1.1-1
- New upstream release

* Sun Nov 01 2009 Sven Lankes <sven@lank.es> 1.0-2
- Add debian patches
- Add tmux group for improved socket handling

* Sat Oct 24 2009 Sven Lankes <sven@lank.es> 1.0-1
- New upstream release

* Mon Jul 13 2009 Chess Griffin <chess@chessgriffin.com> 0.9-1
- Update to version 0.9.
- Remove sed invocation as this was adopted upstream.
- Remove optflags patch since upstream source now uses ./configure and
  detects the flags when passed to make.

* Tue Jun 23 2009 Chess Griffin <chess@chessgriffin.com> 0.8-5
- Note that souce is mostly ISC licensed with some 2 and 3 clause BSD in
  compat/.
- Remove fixiquote.patch and instead use a sed invocation in setup.

* Mon Jun 22 2009 Chess Griffin <chess@chessgriffin.com> 0.8-4
- Add optimization flags by patching GNUmakefile and passing LDFLAGS
  to make command.
- Use consistent macro format.
- Change examples/* to examples/ and add TODO to docs.

* Sun Jun 21 2009 Chess Griffin <chess@chessgriffin.com> 0.8-3
- Remove fixperms.patch and instead pass them at make install stage.

* Sat Jun 20 2009 Chess Griffin <chess@chessgriffin.com> 0.8-2
- Fix Source0 URL to point to correct upstream source.
- Modify fixperms.patch to set 644 permissions on the tmux.1.gz man page.
- Remove wildcards from 'files' section and replace with specific paths and
  filenames.

* Mon Jun 15 2009 Chess Griffin <chess@chessgriffin.com> 0.8-1
- Initial RPM release.
