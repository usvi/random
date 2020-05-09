NOTE: This is IPV4-only solution!



To set up special lookup tables for policy routing,
edit the file /etc/iproute2/rt_tables
and in the bottom add the following two lines

101 eth1
102 eth2



dhclient hook scripts are to be installed for dhclient
(just find /etc | grep dhclient- ), you'll get the picture.



Create /var/lib/routes directory. The scripts fill the gateway
information there automatically for lookups.



For dy.fi updates, create /etc/dy.fi_credentials.dat containing
your dy.fi email and password in one line in the form:
example@gmail.com:password

Also, create directory /var/lib/dyfi . And off course,
fill in dy.fi host info to beginning of the script
dhclient-exit-hooks.d/post-dhcp-settings



Install OpenVPN to port 443/TCP with dev tun. Add the following
stanza to the server.conf so scripts can fill the info in
automatically:

config /etc/openvpn/listen.conf



Naturally, install all sbin scripts to /usr/local/sbin and
ensure they are executable.



Things to add/fix:
* Add updating method to asuka.fi (bound to eth2). This needs
to be updated directly upstream. Currently for example
shell.asuka.fi and www.asuka.fi are CNAME'd to
shell.asuka.dy.fi and asuka.dy.fi, respectively. However,
asuka.fi cannot CNAME other domains, instead it needs to be
purely numerically configured on ISP.
