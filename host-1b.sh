export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y tcpdump --assume-yes
apt-get install -y curl --assume-yes
ip addr add 192.168.2.1/27 dev eth1
ip link set eth1 up
ip route replace 192.168.0.0/16 via 192.168.2.30
