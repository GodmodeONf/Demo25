ena
conf t
hostname hq-rtr
ip domain-name au-team.irpo
interface int0
description "to isp"
ip address 172.16.4.14/28
port te0
service-instance te0/int0
encapsulation untagged
interface int0
connect port te0 service-instance te0/int0
interface int1
description "to hq-srv"
ip address 192.168.1.1/26
port te1
service-instance te1/int1
encapsulation dot1q 100 exact
rewrite pop 1
interface int1
connect port te1 service-instance te1/int1
interface int2
description "to hq-cli"
ip address 192.168.1.65/28
port te1
service-instance te1/int2
encapsulation dot1q 200 exact
rewrite pop 1
interface int2
connect port te1 service-instance te1/int2
interface int3
description "to management"
ip address 192.168.1.81/29
port te1
service-instance te1/int3
encapsulation dot1q 999 exact
rewrite pop 1
interface int3
connect port te1 service-instance te1/int3
exit
ip route 0.0.0.0/0 172.16.4.1
username net_admin
password P@$$word
role admin
exit
int tunnel.0
ip add 172.16.0.1/30
ip mtu 1400
ip tunnel 172.16.4.14 172.16.5.14 mode gre
exit
router ospf 1
router-id 1.1.1.1
network 172.16.0.0/30 area 0
network 192.168.1.0/26 area 0
network 192.168.1.64/28 area 0
network 192.168.1.80/29 area 0
passive-interface default
no passive-interface tunnel.0
exit
int tunnel.0
ip ospf authentication message-digest
ip ospf message-digest-key 1 md5 P@ssw0rd
exit
int int1
ip nat inside
int int2
ip nat inside
int int3
ip nat inside
int int0
ip nat outside
exit
ip nat pool NAT_POOL 192.168.1.1-192.168.1.62,192.168.1.65-192.168.1.78,192.168.1.81-192.168.1.87
ip nat source dynamic inside-to-outside pool NAT_POOL overload interface int0
ip pool cli_pool 1 
range 192.168.1.66-192.168.1.78
exit
dhcp-server 1
pool cli_pool 1
mask 255.255.255.240
gateway 192.168.1.65
dns 192.168.100.62
domain-name au-team.irpo
interface int2
dhcp-server 1
exit
ntp timezone utc+4
ip nat source static tcp 192.168.100.2 2024 172.16.4.14 2024
security none
exit
wr mem
