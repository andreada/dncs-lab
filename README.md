# DNCS-LAB Assignment A.Y. 2018/2019
project by Andrea Dall'Acqua and Anna Scremin for the course of "Design of Networks and Communication Systems"  
University of Trento

## Table of contents

- [Assignment](#assigment)
- [Network map](#network-map)
- [Requirements](#requirements)
- [Network configuration](#network-configuration)
 - [Subnetting](#subnetting)
 - [VLANs](#vlans)
 - [Interface-IP mapping](#interface-ip-mapping)
- [Vagrant file](#vagrant-file)
- [Provisioning scripts](provisioning-scripts)
  - [Router-1](#router-1)
  - [Router-2](#router-2)
  - [Switch](#switch)
  - [Host-1-a](#host-1-a)
  - [Host-1-b](#host-1-b)
  - [Host-2-c](#host-2-c)
- [How-to](#how-to)
  - [Host-1-a test](#host-1-a-test)
  - [Host-1-b test](#host-1-b-test)
  - [Switch test](#switch-test)
  - [Router-1 test](#router-1-test)
  - [Router-2 test](#router-2-test)
  - [Host-2-c test](#host-2-c-test)

## Assignment
Based the Vagrantfile and the provisioning scripts available at: https://github.com/dustnic/dncs-lab the candidate is required to design a functioning network where any host configured
and attached to router-1 (through switch) can browse a website hosted on host-2-c.
The subnetting needs to be designed to accommodate the following requirement (no need to create more hosts than the one described in the vagrantfile):
- Up to 130 hosts in the same subnet of host-1-a
- Up to 25 hosts in the same subnet of host-1-b
- Consume as few IP addresses as possible

## Network map

        +-----------------------------------------------------+
        |                                                     |
        |                                                     |eth0
        +--+--+                +------------+             +------------+
        |     |                |            |             |            |
        |     |            eth0|            |eth2     eth2|            |
        |     +----------------+  router-1  +-------------+  router-2  |
        |     |                |            |             |            |
        |     |                |            |             |            |
        |  M  |                +------------+             +------------+
        |  A  |                      |eth1                       |eth1
        |  N  |                      |                           |
        |  A  |                      |                           |
        |  G  |                      |                     +-----+----+
        |  E  |                      |eth1                 |          |
        |  M  |            +-------------------+           |          |
        |  E  |        eth0|                   |           | host-2-c |
        |  N  +------------+      SWITCH       |           |          |
        |  T  |            |                   |           |          |
        |     |            +-------------------+           +----------+
        |  V  |               |eth2         |eth3                |eth0
        |  A  |               |             |                    |
        |  G  |               |             |                    |
        |  R  |               |eth1         |eth1                |
        |  A  |        +----------+     +----------+             |
        |  N  |        |          |     |          |             |
        |  T  |    eth0|          |     |          |             |
        |     +--------+ host-1-a |     | host-1-b |             |
        |     |        |          |     |          |             |
        |     |        |          |     |          |             |
        ++-+--+        +----------+     +----------+             |
        | |                              |eth0                  |
        | |                              |                      |
        | +------------------------------+                      |
        |                                                       |
        |                                                       |
        +-------------------------------------------------------+

## Requirements
- 10GB disk storage
- 2GB free RAM
- Virtualbox
- Vagrant (https://www.vagrantup.com)
- Internet

## Network configuration
### Subnetting
We decided to divide our network in 4 different subnets (2 of these Vlan based):
- A: contains *host-1-a* and *router-1* and other 128 hosts(Vlan based)
- B: contains *host-1-b* and *router-1* and other 23 hosts(Vlan based)
- C: contains *host-2-c* and *router-2*
- D: contains *router-1* and *router-2*

We chose the netmasks according to the project's requirements:

| Subnet | Network address  | Network Mask          |# Requested IPs  | # Available IPs       |
| -----  |:---------------- |:--------------------- |:---------------:|:---------------------|
| A      | 192.168.1.0      | 255.255.255.0 (/24)   |       130       |2<sup>32-24</sup>-2=254|
| B      | 192.168.2.0      | 255.255.224.0 (/27)   |       25        |2<sup>32-27</sup>-2=30 |
| C      | 192.168.3.0      | 255.255.255.252 (/30) |       2         |2<sup>32-30</sup>-2=2  |
| D      | 192.168.255.252  | 255.255.255.252 (/30) |       2         |2<sup>32-30</sup>-2=2  |

To calculate the number of available IPs we used the following formula:  
Available IPs=2<sup>32-N</sup>-2  
- 32 is the number of bit that compose an ip address
- N is the number of bit equal to 1 in the subnet mask
- -2 because there are 2 reserved ip(one for network and one for broadcast)

### VLANs
Due to only one connection between *router-1* and *switch*, we decided to create 2 different Vlans for the networks A and B with the following VIDs:

| Subnet | VID |
|:-----: | :--: |
|A|11|
|B|12|

### Interface-IP mapping

|Device	  |Interface	|IP                 |Subnet|
|:-------:|:----------|:------------------|:----:|
|host-1-a	|eth1	      |192.168.1.1/24     |	 A   |
|router-1	|eth1.11    |192.168.1.254/24   |  A   |
|host-1-b	|eth1      	|192.168.2.1/27     |  B   |
|router-1	|eth1.12    |192.168.2..30/27   |  B   |
|host-2-c	|eth1	      |192.168.3.1/30     |  C   |
|router-2	|eth1	      |192.168.3.2/30     |  C   |
|router-1	|eth2	      |192.168.255.253/30 |  D   |
|router-2	|eth2	      |192.168.255.254/30 |  D   |

## Vagrant file

The vagrant file is used to inizialize each virtual machine and the links between them.
Now we will discuss how this works taking *router-1* inizialization as an example(the structure is similiar for each vm ):
```
config.vm.define "router-1" do |router1|
  router1.vm.box = "minimal/trusty64"
  router1.vm.hostname = "router-1"
  router1.vm.network "private_network", virtualbox__intnet: "broadcast_router-south-1", auto_config: false
  router1.vm.network "private_network", virtualbox__intnet: "broadcast_router-inter", auto_config: false
  router1.vm.provision "shell", path: "router1.sh"
end
```
With these lines we created and configured a virtual machine based on trusty64 named *router-1*.
Then we added 2 interfaces and created "router1.sh", a script that contains all the commands to configure the vm.

## Provisioning scripts

### Router-1
In router1.sh with the following lines we added 2 vlan links to configure the trunk port between *router-1* and *switch*:
```
ip link add link eth1 name eth1.11 type vlan id 11
ip link add link eth1 name eth1.12 type vlan id 12
```
We assigned ip addresses for each interface:
```
ip addr add 192.168.1.254/24 dev eth1.11
ip addr add 192.168.2.30/27 dev eth1.12
ip addr add 192.168.255.253/30 dev eth2
```
Set them up:
```
ip link set eth1 up
ip link set eth1.11 up
ip link set eth1.12 up
```
And at the end, to implement a dynamic routing between *router-1* and *router-2*,we enabled IP forwarding and FRRouting configuring OSPF protocol:
```
sysctl net.ipv4.ip_forward=1
sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
service frr restart
vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
```

### Router-2

in router2.sh with the following lines we assigned ip addresses for each interface:
```
ip addr add 192.168.3.2/30 dev eth1
ip addr add 192.168.255.254/30 dev eth2
```
Set them up:
```
ip link set eth1 up
ip link set eth2 up
```
And at the end, to implement a dynamic routing between *router-1* and *router-2*,we enabled IP forwarding and FRRouting configuring OSPF protocol:
```
sysctl net.ipv4.ip_forward=1
sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
service frr restart
vtysh -c 'configure terminal' -c 'interface eth2' -c 'ip ospf area 0.0.0.0'
vtysh -c 'configure terminal' -c 'router ospf' -c 'redistribute connected'
```

### Switch

in switch.sh with the following lines we created a bridge named switch and added interfaces to it(eth1 for the trunk port, eth2 for the VLAN with the tag 11, eth3 for the Vlan with the tag 12 ):
```
ovs-vsctl add-br switch
ovs-vsctl add-port switch eth1
ovs-vsctl add-port switch eth2 tag=11
ovs-vsctl add-port switch eth3 tag=12
```
We set interfaces up:
```
ip link set eth1 up
ip link set eth2 up
ip link set eth3 up
```
And at the end we set  ovs-system up:
```
ip link set dev ovs-system up
```
### Host-1-a

in host-1a.sh with the following lines we assigned ip address to interface *eth1*:
```
ip addr add 192.168.1.1/24 dev eth1
```
Set it up:
```
ip link set eth1 up
```
And at the end we set a static route to *router-1*:
```
ip route replace 192.168.0.0/16 via 192.168.1.254
```
### Host-1-b

in host-1b.sh with the following lines we assigned ip address to interface *eth1*:
```
ip addr add 192.168.2.1/27 dev eth1
```
Set it up:
```
ip link set eth1 up
```
And at the end we set a static route to *router-1*:
```
ip route replace 192.168.0.0/16 via 192.168.2.30
```

### Host-2-c

in host-2c.sh with the following lines, due to compatibility issues, we installed docker version 18.06.1:
```
apt-get install -y apt-transport-https ca-certificates curl software-properties-common --assume-yes --force-yes
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu jq --assume-yes --force-yes
```
Then we assigned ip address to interface *eth1*:
```
ip addr add 192.168.3.1/30 dev eth1
```
Set it up:
```
ip link set eth1 up
```
Set a static route to *router-2*:
```
ip route replace 192.168.0.0/16 via 192.168.3.2
```
With the following command we kill all docker containers:
```
docker rm $(docker ps -aq)
```
And then we created a webserver named *hostc-webserver* on port 80 using an apache webserver image:
```
docker run -dit --name hostc-webserver -p 80:80 -v /var/www/:/usr/local/apache2/htdocs/ httpd:2.4
```
Finally we wrote a simple HTML web page:
```
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>progetto di Andrea e Anna</title>
</head>
<body>
    <h1>The cake is a lie</h1>
</body>
</html>" > /var/www/index.html
```

## How-to

- install Virtualbox and Vagrant
- Clone this repository `git clone https://github.com/andreada/dncs-lab`
- You should be able to launch the lab from within the cloned repo folder.
```
cd dncs-lab
~/dncs-lab$ vagrant up --provision
```
`--provision` isn't necessary on first launch because it will do it by default.
Once you launch the vagrant script, it may take a while for the entire topology to become available.
-Verify the status of the 4 VMs:
```
vagrant status
```
The output will be:
```
Current machine states:
router-1                  running (virtualbox)
router-2                  running (virtualbox)
switch                    running (virtualbox)
host-1-a                  running (virtualbox)
host-1-b                  running (virtualbox)
host-2-c                  running (virtualbox)
```
- Now we can log into each VM:
```
vagrant ssh router-1
```
```
vagrant ssh router-2
```
```
vagrant ssh switch
```
```
vagrant ssh host-1-a
```
```
vagrant ssh host-1-b
```
```
vagrant ssh host-2-c
```
To log out write `exit`

### Host-1-a test

Once you have log into the VM of *host-1-a* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1051 errors:0 dropped:0 overruns:0 frame:0
          TX packets:746 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:127811 (127.8 KB)  TX bytes:136518 (136.5 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:e8:97:77
          inet addr:192.168.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fee8:9777/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:11 errors:0 dropped:0 overruns:0 frame:0
          TX packets:23 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1516 (1.5 KB)  TX bytes:1796 (1.7 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```
- eth0 is the interface that links VM with our pc
- eth1 is the interface that links the *host-1-a* with the *switch*  
- lo is a special network interface that the system uses to communicate with itself  

Then you can test the reachability of *host-1-b* with the command `ping 192.168.2.1` and expect the following result :
```
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=63 time=1.80 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=63 time=0.949 ms
64 bytes from 192.168.2.1: icmp_seq=3 ttl=63 time=0.819 ms
64 bytes from 192.168.2.1: icmp_seq=4 ttl=63 time=0.925 ms
64 bytes from 192.168.2.1: icmp_seq=5 ttl=63 time=0.742 ms
^C
--- 192.168.2.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4002ms
rtt min/avg/max/mdev = 0.742/1.047/1.802/0.385 ms
```
Test the reachability of *host-2-c* with the command `ping 192.168.3.1`and expect the following result :
```
PING 192.168.3.1 (192.168.3.1) 56(84) bytes of data.
64 bytes from 192.168.3.1: icmp_seq=1 ttl=62 time=1.56 ms
64 bytes from 192.168.3.1: icmp_seq=2 ttl=62 time=1.27 ms
64 bytes from 192.168.3.1: icmp_seq=3 ttl=62 time=0.846 ms
64 bytes from 192.168.3.1: icmp_seq=4 ttl=62 time=1.02 ms
64 bytes from 192.168.3.1: icmp_seq=5 ttl=62 time=0.976 ms
^C
--- 192.168.3.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4004ms
rtt min/avg/max/mdev = 0.846/1.136/1.567/0.257 ms
```
Test the reachability of the web server with the command `curl 192.168.3.1:80/index.html` and expect the following result:
```
<!DOCTYPE html>
<html lang=en>
<head>
    <meta charset=UTF-8>
    <title>progetto di Andrea e Anna</title>
</head>
<body>
    <h1>The cake is a lie</h1>
</body>
</html>
```

### Host-1-b test

Once you have log into the VM of *host-1-b* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:10910 errors:0 dropped:0 overruns:0 frame:0
          TX packets:4307 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:9885661 (9.8 MB)  TX bytes:391995 (391.9 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:43:12:f0
          inet addr:192.168.2.1  Bcast:0.0.0.0  Mask:255.255.255.224
          inet6 addr: fe80::a00:27ff:fe43:12f0/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:5 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:414 (414.0 B)  TX bytes:1062 (1.0 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

Then you can test the reachability of *host-1-a* with the command `ping 192.168.1.1` and expect the following result :
```
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=63 time=1.01 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=63 time=0.858 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=63 time=0.819 ms
64 bytes from 192.168.1.1: icmp_seq=4 ttl=63 time=1.15 ms
64 bytes from 192.168.1.1: icmp_seq=5 ttl=63 time=1.37 ms
^C
--- 192.168.1.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4004ms
rtt min/avg/max/mdev = 0.819/1.045/1.379/0.207 ms
```
Test the reachability of *host-2-c* with the command `ping 192.168.3.1`and expect the following result :
```
PING 192.168.3.1 (192.168.3.1) 56(84) bytes of data.
64 bytes from 192.168.3.1: icmp_seq=1 ttl=62 time=1.38 ms
64 bytes from 192.168.3.1: icmp_seq=2 ttl=62 time=1.76 ms
64 bytes from 192.168.3.1: icmp_seq=3 ttl=62 time=0.942 ms
64 bytes from 192.168.3.1: icmp_seq=4 ttl=62 time=1.13 ms
64 bytes from 192.168.3.1: icmp_seq=5 ttl=62 time=0.979 ms
^C
--- 192.168.3.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4006ms
rtt min/avg/max/mdev = 0.942/1.242/1.766/0.305 ms
```
Test the reachability of the web server with the command `curl 192.168.3.1:80/index.html` and expect the following result:
```
<!DOCTYPE html>
<html lang=en>
<head>
    <meta charset=UTF-8>
    <title>progetto di Andrea e Anna</title>
</head>
<body>
    <h1>The cake is a lie</h1>
</body>
</html>
```
### Switch test

Once you have log into the VM of *switch* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:15098 errors:0 dropped:0 overruns:0 frame:0
          TX packets:5513 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:14426255 (14.4 MB)  TX bytes:487678 (487.6 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:06:e8:b2
          inet6 addr: fe80::a00:27ff:fe06:e8b2/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:23 errors:0 dropped:0 overruns:0 frame:0
          TX packets:57 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2302 (2.3 KB)  TX bytes:4721 (4.7 KB)

eth2      Link encap:Ethernet  HWaddr 08:00:27:d7:55:ee
          inet6 addr: fe80::a00:27ff:fed7:55ee/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:30 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:2543 (2.5 KB)  TX bytes:2536 (2.5 KB)

eth3      Link encap:Ethernet  HWaddr 08:00:27:69:8a:28
          inet6 addr: fe80::a00:27ff:fe69:8a28/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:13 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:1062 (1.0 KB)  TX bytes:1062 (1.0 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:16 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1184 (1.1 KB)  TX bytes:1184 (1.1 KB)

ovs-system Link encap:Ethernet  HWaddr 96:fd:e3:11:b6:18
          inet6 addr: fe80::94fd:e3ff:fe11:b618/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)

switch    Link encap:Ethernet  HWaddr 08:00:27:06:e8:b2
          inet6 addr: fe80::f45d:bdff:feec:ff15/64 Scope:Link
          UP BROADCAST RUNNING  MTU:1500  Metric:1
          RX packets:18 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1420 (1.4 KB)  TX bytes:648 (648.0 B)                  
```
- eth1 is the interface that links the *switch* with the *router-1*  
- eth2 is the interface that links the *switch* with the *host-1-a*
- eth3 is the interface that links the *switch* with the *host-1-b*

### Router-1 test

Once you have log into the VM of *router-1* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44                        
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0            
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link                   
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                   
          RX packets:1294 errors:0 dropped:0 overruns:0 frame:0                
          TX packets:976 errors:0 dropped:0 overruns:0 carrier:0               
          collisions:0 txqueuelen:1000                                         
          RX bytes:198029 (198.0 KB)  TX bytes:191843 (191.8 KB)               

eth1      Link encap:Ethernet  HWaddr 08:00:27:1f:9e:23                        
          inet6 addr: fe80::a00:27ff:fe1f:9e23/64 Scope:Link                   
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                   
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                   
          TX packets:24 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:1000                                         
          RX bytes:0 (0.0 B)  TX bytes:1944 (1.9 KB)                           

eth2      Link encap:Ethernet  HWaddr 08:00:27:d8:28:dd                        
          inet addr:192.168.255.253  Bcast:0.0.0.0  Mask:255.255.255.252       
          inet6 addr: fe80::a00:27ff:fed8:28dd/64 Scope:Link                   
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                   
          RX packets:144 errors:0 dropped:0 overruns:0 frame:0                 
          TX packets:175 errors:0 dropped:0 overruns:0 carrier:0               
          collisions:0 txqueuelen:1000                                         
          RX bytes:12320 (12.3 KB)  TX bytes:14698 (14.6 KB)                   

eth1.11   Link encap:Ethernet  HWaddr 08:00:27:1f:9e:23                        
          inet addr:192.168.1.254  Bcast:0.0.0.0  Mask:255.255.255.0           
          inet6 addr: fe80::a00:27ff:fe1f:9e23/64 Scope:Link                   
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                   
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                   
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0                 
          collisions:0 txqueuelen:0                                            
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)                           

eth1.12   Link encap:Ethernet  HWaddr 08:00:27:1f:9e:23                        
          inet addr:192.168.2.30  Bcast:0.0.0.0  Mask:255.255.255.224          
          inet6 addr: fe80::a00:27ff:fe1f:9e23/64 Scope:Link                   
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                   
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                   
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0                 
          collisions:0 txqueuelen:0                                            
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)                           

lo        Link encap:Local Loopback                                            
          inet addr:127.0.0.1  Mask:255.0.0.0                                  
          inet6 addr: ::1/128 Scope:Host                                       
          UP LOOPBACK RUNNING  MTU:65536  Metric:1                             
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:16 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:0                                            
          RX bytes:1184 (1.1 KB)  TX bytes:1184 (1.1 KB)                       
```
- eth1 is the interface that links the *router-1* with the *switch*  
- eth2 is the interface that links the *router-1* with the *router-2*
- eth1.11 is the interface of the Vlan that links the *router-1* with the *host-1-a*
- eth1.12 is the interface of the Vlan that links the *router-1* with the *host-1-b*

The command `route -n` displays the ip routing table:
```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG    0      0        0 eth0
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 eth1.11
192.168.2.0     0.0.0.0         255.255.255.224 U     0      0        0 eth1.12
192.168.3.0     192.168.255.254 255.255.255.252 UG    20     0        0 eth2
192.168.255.252 0.0.0.0         255.255.255.252 U     0      0        0 eth2
```
### Router-2 test
Once you have log into the VM of *router-2* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:1318 errors:0 dropped:0 overruns:0 frame:0
          TX packets:999 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:200024 (200.0 KB)  TX bytes:193344 (193.3 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:4a:a6:b3
          inet addr:192.168.3.2  Bcast:0.0.0.0  Mask:255.255.255.252
          inet6 addr: fe80::a00:27ff:fe4a:a6b3/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)

eth2      Link encap:Ethernet  HWaddr 08:00:27:ba:41:de
          inet addr:192.168.255.254  Bcast:0.0.0.0  Mask:255.255.255.252
          inet6 addr: fe80::a00:27ff:feba:41de/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:248 errors:0 dropped:0 overruns:0 frame:0
          TX packets:260 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:21028 (21.0 KB)  TX bytes:21812 (21.8 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)                   
```
- eth1 is the interface that links the *router-2* with the *host-2-c*  
- eth2 is the interface that links the *router-2* with the *router-1*

The command `route -n` displays the ip routing table:
```
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         10.0.2.2        0.0.0.0         UG    0      0        0 eth0
10.0.2.0        0.0.0.0         255.255.255.0   U     0      0        0 eth0
192.168.1.0     192.168.255.253 255.255.255.0   UG    20     0        0 eth2
192.168.2.0     192.168.255.253 255.255.255.224 UG    20     0        0 eth2
192.168.3.0     0.0.0.0         255.255.255.252 U     0      0        0 eth1
192.168.255.252 0.0.0.0         255.255.255.252 U     0      0        0 eth2
```
### Host-2-c test
Once you have log into the VM of *host-2-c* and used command `sudo su` to get superuser permission, you can use the command `ifconfig` to display all the information about the ethernet interfaces of the host. The output should be:
```
docker0   Link encap:Ethernet  HWaddr 02:42:76:07:0d:22                       
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0        
          inet6 addr: fe80::42:76ff:fe07:d22/64 Scope:Link                    
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                  
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:0                                           
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)                          

eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44                       
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0           
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link                  
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                  
          RX packets:915 errors:0 dropped:0 overruns:0 frame:0                
          TX packets:681 errors:0 dropped:0 overruns:0 carrier:0              
          collisions:0 txqueuelen:1000                                        
          RX bytes:142765 (142.7 KB)  TX bytes:128452 (128.4 KB)              

eth1      Link encap:Ethernet  HWaddr 08:00:27:a1:df:9a                       
          inet addr:192.168.3.1  Bcast:0.0.0.0  Mask:255.255.255.252          
          inet6 addr: fe80::a00:27ff:fea1:df9a/64 Scope:Link                  
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                  
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:1000                                        
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)                          

lo        Link encap:Local Loopback                                           
          inet addr:127.0.0.1  Mask:255.0.0.0                                 
          inet6 addr: ::1/128 Scope:Host                                      
          UP LOOPBACK RUNNING  MTU:65536  Metric:1                            
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:0                                           
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)                              

veth0556446 Link encap:Ethernet  HWaddr 0e:12:1f:45:6e:09                     
          inet6 addr: fe80::c12:1fff:fe45:6e09/64 Scope:Link                  
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                  
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:16 errors:0 dropped:0 overruns:0 carrier:0               
          collisions:0 txqueuelen:0                                           
          RX bytes:0 (0.0 B)  TX bytes:1296 (1.2 KB)                          

```
- eth1 is the interface that links the *host-2-c* with the *router-2*
