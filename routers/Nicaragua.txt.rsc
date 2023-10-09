# oct/09/2023 10:41:26 by RouterOS 7.8
# software id = 
#
/disk
set slot1 slot=slot1
set slot2 slot=slot2
set slot3 slot=slot3
set slot4 slot=slot4
set slot5 slot=slot5
set slot6 slot=slot6
set slot7 slot=slot7
set slot8 slot=slot8
set slot9 slot=slot9
set slot10 slot=slot10
set slot11 slot=slot11
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/port
set 0 name=serial0
/routing ospf instance
add disabled=no name=v2 originate-default=never router-id=1.1.1.1
add disabled=no name=v3 originate-default=never router-id=1.1.1.1 version=3
/routing ospf area
add disabled=no instance=v2 name=ospf-area-1
add disabled=no instance=v3 name=ospf-area-2
/ip address
add address=192.168.144.1/30 interface=ether1 network=192.168.144.0
/ip dhcp-client
add interface=ether1
/ipv6 address
add address=2001:20:23:13:2::1/80 advertise=no interface=ether1
/routing ospf interface-template
add area=ospf-area-1 disabled=no interfaces=ether1,ether2,ether3
