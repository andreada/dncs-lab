export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tcpdump apt-transport-https ca-certificates curl software-properties-common --assume-yes --force-yes
wget -O- https://apps3.cumulusnetworks.com/setup/cumulus-apps-deb.pubkey | apt-key add -
add-apt-repository "deb [arch=amd64] https://apps3.cumulusnetworks.com/repos/deb $(lsb_release -cs) roh-3"
apt-get update
apt-get install -y frr --assume-yes --force-yes
ip link add link eth1 name eth1.11 type vlan id 11
ip link add link eth1 name eth1.12 type vlan id 12
ip addr add 192.168.1.254/24 dev eth1.11
ip addr add 192.168.2.30/27 dev eth1.12
ip addr add 192.168.255.253/30 dev eth2
ip link set eth1 up
ip link set eth1.11 up
ip link set eth1.12 up
ip link set eth2 up
sysctl net.ipv4.ip_forward=1
sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
service frr restart
vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
