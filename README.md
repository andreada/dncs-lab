# DNCS-LAB Assignment A.Y. 2018/2019
project by Andrea Dall'Acqua and Anna Scremin for the course of "Design of Networks and Communication Systems"  
University of Trento

## Table of contents

- [Assignment](#assignment)
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
apt-get update
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
          RX packets:10773 errors:0 dropped:0 overruns:0 frame:0
          TX packets:4194 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:9876987 (9.8 MB)  TX bytes:382567 (382.5 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:c6:d8:c8
          inet addr:192.168.1.1  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fec6:d8c8/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
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
- eth0 is the interface that links VM with our pc
- eth1 is the interface that links the *host-1-a* with the *switch*  
- lo is a special network interface that the system uses to communicate with itself  

Then you can test the reachability of *host-1-b* with the command `ping 192.168.2.1` and expect the following result :
```
PING 192.168.2.1 (192.168.2.1) 56(84) bytes of data.
64 bytes from 192.168.2.1: icmp_seq=1 ttl=63 time=2.01 ms
64 bytes from 192.168.2.1: icmp_seq=2 ttl=63 time=0.808 ms
64 bytes from 192.168.2.1: icmp_seq=3 ttl=63 time=0.699 ms
^C
--- 192.168.2.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 0.699/1.173/2.014/0.597 ms
```
Test the reachability of *host-2-c* with the command `ping 192.168.3.1`and expect the following result :
```
PING 192.168.3.1 (192.168.3.1) 56(84) bytes of data.
64 bytes from 192.168.3.1: icmp_seq=1 ttl=62 time=1.58 ms
64 bytes from 192.168.3.1: icmp_seq=2 ttl=62 time=1.04 ms
64 bytes from 192.168.3.1: icmp_seq=3 ttl=62 time=1.16 ms
^C
--- 192.168.3.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 1.045/1.262/1.580/0.233 ms
```
Test the reachability of the web server with the command `curl 192.168.3.1` and expect the following result:
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
          RX packets:10324 errors:0 dropped:0 overruns:0 frame:0
          TX packets:3586 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:9852824 (9.8 MB)  TX bytes:346427 (346.4 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:d1:46:ab
          inet addr:192.168.2.1  Bcast:0.0.0.0  Mask:255.255.255.224
          inet6 addr: fe80::a00:27ff:fed1:46ab/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:5 errors:0 dropped:0 overruns:0 frame:0
          TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:414 (414.0 B)  TX bytes:1062 (1.0 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:16 errors:0 dropped:0 overruns:0 frame:0
          TX packets:16 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1184 (1.1 KB)  TX bytes:1184 (1.1 KB)
```
- eth0 is the interface that links VM with our pc
- eth1 is the interface that links the *host-1-b* with the *switch*  
- lo is a special network interface that the system uses to communicate with itself  

Then you can test the reachability of *host-1-a* with the command `ping 192.168.1.1` and expect the following result :
```
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=63 time=8.45 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=63 time=1.02 ms
64 bytes from 192.168.1.1: icmp_seq=3 ttl=63 time=1.02 ms
^C
--- 192.168.1.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2004ms
rtt min/avg/max/mdev = 1.022/3.498/8.451/3.502 ms
```
Test the reachability of *host-2-c* with the command `ping 192.168.3.1`and expect the following result :
```
PING 192.168.3.1 (192.168.3.1) 56(84) bytes of data.
64 bytes from 192.168.3.1: icmp_seq=1 ttl=62 time=2.14 ms
64 bytes from 192.168.3.1: icmp_seq=2 ttl=62 time=2.39 ms
64 bytes from 192.168.3.1: icmp_seq=3 ttl=62 time=1.04 ms
^C
--- 192.168.3.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.047/1.864/2.398/0.589 ms
```
Test the reachability of the web server with the command `curl 192.168.3.1` and expect the following result:
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
          RX packets:14604 errors:0 dropped:0 overruns:0 frame:0    
          TX packets:5024 errors:0 dropped:0 overruns:0 carrier:0   
          collisions:0 txqueuelen:1000                              
          RX bytes:14399543 (14.3 MB)  TX bytes:457582 (457.5 KB)   

eth1      Link encap:Ethernet  HWaddr 08:00:27:ee:ac:a2             
          inet6 addr: fe80::a00:27ff:feee:aca2/64 Scope:Link        
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1        
          RX packets:36 errors:0 dropped:0 overruns:0 frame:0       
          TX packets:71 errors:0 dropped:0 overruns:0 carrier:0     
          collisions:0 txqueuelen:1000                              
          RX bytes:3700 (3.7 KB)  TX bytes:5824 (5.8 KB)            

eth2      Link encap:Ethernet  HWaddr 08:00:27:95:68:3a             
          inet6 addr: fe80::a00:27ff:fe95:683a/64 Scope:Link        
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1        
          RX packets:28 errors:0 dropped:0 overruns:0 frame:0       
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0     
          collisions:0 txqueuelen:1000                              
          RX bytes:2309 (2.3 KB)  TX bytes:2498 (2.4 KB)            

eth3      Link encap:Ethernet  HWaddr 08:00:27:f5:c6:df             
          inet6 addr: fe80::a00:27ff:fef5:c6df/64 Scope:Link        
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1        
          RX packets:28 errors:0 dropped:0 overruns:0 frame:0       
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0     
          collisions:0 txqueuelen:1000                              
          RX bytes:2309 (2.3 KB)  TX bytes:2498 (2.4 KB)            

lo        Link encap:Local Loopback                                 
          inet addr:127.0.0.1  Mask:255.0.0.0                       
          inet6 addr: ::1/128 Scope:Host                            
          UP LOOPBACK RUNNING  MTU:65536  Metric:1                  
          RX packets:8 errors:0 dropped:0 overruns:0 frame:0        
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0      
          collisions:0 txqueuelen:0                                 
          RX bytes:688 (688.0 B)  TX bytes:688 (688.0 B)            

ovs-system Link encap:Ethernet  HWaddr 76:5f:9f:d7:e4:18            
          inet6 addr: fe80::745f:9fff:fed7:e418/64 Scope:Link       
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1        
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0        
          TX packets:8 errors:0 dropped:0 overruns:0 carrier:0      
          collisions:0 txqueuelen:0                                 
          RX bytes:0 (0.0 B)  TX bytes:648 (648.0 B)                

switch    Link encap:Ethernet  HWaddr 08:00:27:95:68:3a             
          inet6 addr: fe80::94ba:30ff:fe8e:d31e/64 Scope:Link       
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
          RX packets:24042 errors:0 dropped:0 overruns:0 frame:0
          TX packets:8665 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:23406360 (23.4 MB)  TX bytes:731867 (731.8 KB)

eth1      Link encap:Ethernet  HWaddr 08:00:27:7a:96:01
          inet6 addr: fe80::a00:27ff:fe7a:9601/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:40 errors:0 dropped:0 overruns:0 frame:0
          TX packets:60 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:3322 (3.3 KB)  TX bytes:5644 (5.6 KB)

eth2      Link encap:Ethernet  HWaddr 08:00:27:5a:ef:df
          inet addr:192.168.255.253  Bcast:0.0.0.0  Mask:255.255.255.252
          inet6 addr: fe80::a00:27ff:fe5a:efdf/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:161 errors:0 dropped:0 overruns:0 frame:0
          TX packets:200 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:14402 (14.4 KB)  TX bytes:16782 (16.7 KB)

eth1.11   Link encap:Ethernet  HWaddr 08:00:27:7a:96:01
          inet addr:192.168.1.254  Bcast:0.0.0.0  Mask:255.255.255.0
          inet6 addr: fe80::a00:27ff:fe7a:9601/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:20 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1381 (1.3 KB)  TX bytes:2408 (2.4 KB)

eth1.12   Link encap:Ethernet  HWaddr 08:00:27:7a:96:01
          inet addr:192.168.2.30  Bcast:0.0.0.0  Mask:255.255.255.224
          inet6 addr: fe80::a00:27ff:fe7a:9601/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:20 errors:0 dropped:0 overruns:0 frame:0
          TX packets:26 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:1381 (1.3 KB)  TX bytes:2408 (2.4 KB)

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)                      
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
          RX packets:23247 errors:0 dropped:0 overruns:0 frame:0                
          TX packets:7841 errors:0 dropped:0 overruns:0 carrier:0               
          collisions:0 txqueuelen:1000                                          
          RX bytes:23363052 (23.3 MB)  TX bytes:683797 (683.7 KB)               

eth1      Link encap:Ethernet  HWaddr 08:00:27:d5:eb:b6                         
          inet addr:192.168.3.2  Bcast:0.0.0.0  Mask:255.255.255.252            
          inet6 addr: fe80::a00:27ff:fed5:ebb6/64 Scope:Link                    
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                    
          RX packets:19 errors:0 dropped:0 overruns:0 frame:0                   
          TX packets:31 errors:0 dropped:0 overruns:0 carrier:0                 
          collisions:0 txqueuelen:1000                                          
          RX bytes:2224 (2.2 KB)  TX bytes:2494 (2.4 KB)                        

eth2      Link encap:Ethernet  HWaddr 08:00:27:88:49:f2                         
          inet addr:192.168.255.254  Bcast:0.0.0.0  Mask:255.255.255.252        
          inet6 addr: fe80::a00:27ff:fe88:49f2/64 Scope:Link                    
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1                    
          RX packets:173 errors:0 dropped:0 overruns:0 frame:0                  
          TX packets:181 errors:0 dropped:0 overruns:0 carrier:0                
          collisions:0 txqueuelen:1000                                          
          RX bytes:14756 (14.7 KB)  TX bytes:15946 (15.9 KB)                    

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
docker0   Link encap:Ethernet  HWaddr 02:42:32:d5:3b:0a                  
          inet addr:172.17.0.1  Bcast:172.17.255.255  Mask:255.255.0.0   
          inet6 addr: fe80::42:32ff:fed5:3b0a/64 Scope:Link              
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1             
          RX packets:11 errors:0 dropped:0 overruns:0 frame:0            
          TX packets:23 errors:0 dropped:0 overruns:0 carrier:0          
          collisions:0 txqueuelen:0                                      
          RX bytes:1308 (1.3 KB)  TX bytes:1732 (1.7 KB)                 

eth0      Link encap:Ethernet  HWaddr 08:00:27:20:c5:44                  
          inet addr:10.0.2.15  Bcast:10.0.2.255  Mask:255.255.255.0      
          inet6 addr: fe80::a00:27ff:fe20:c544/64 Scope:Link             
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1             
          RX packets:92201 errors:0 dropped:0 overruns:0 frame:0         
          TX packets:11984 errors:0 dropped:0 overruns:0 carrier:0       
          collisions:0 txqueuelen:1000                                   
          RX bytes:117427633 (117.4 MB)  TX bytes:958752 (958.7 KB)      

eth1      Link encap:Ethernet  HWaddr 08:00:27:e3:3f:df                  
          inet addr:192.168.3.1  Bcast:0.0.0.0  Mask:255.255.255.252     
          inet6 addr: fe80::a00:27ff:fee3:3fdf/64 Scope:Link             
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1             
          RX packets:23 errors:0 dropped:0 overruns:0 frame:0            
          TX packets:27 errors:0 dropped:0 overruns:0 carrier:0          
          collisions:0 txqueuelen:1000                                   
          RX bytes:1846 (1.8 KB)  TX bytes:2872 (2.8 KB)                 

lo        Link encap:Local Loopback                                      
          inet addr:127.0.0.1  Mask:255.0.0.0                            
          inet6 addr: ::1/128 Scope:Host                                 
          UP LOOPBACK RUNNING  MTU:65536  Metric:1                       
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0             
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0           
          collisions:0 txqueuelen:0                                      
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)                         

veth1856c12 Link encap:Ethernet  HWaddr c2:8a:b7:b5:18:4d                
          inet6 addr: fe80::c08a:b7ff:feb5:184d/64 Scope:Link            
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1             
          RX packets:11 errors:0 dropped:0 overruns:0 frame:0            
          TX packets:31 errors:0 dropped:0 overruns:0 carrier:0          
          collisions:0 txqueuelen:0                                      
          RX bytes:1462 (1.4 KB)  TX bytes:2380 (2.3 KB)                                          

```
- eth1 is the interface that links the *host-2-c* with the *router-2*
