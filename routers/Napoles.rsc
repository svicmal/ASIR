# oct/05/2023 19:30:02 by RouterOS 7.8
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
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/port
set 0 name=serial0
/routing ospf instance
add disabled=no name=v2 router-id=6.6.6.6
add disabled=no name=v3 router-id=6.6.6.6 version=3
/routing ospf area
add disabled=no instance=v2 name=ospf-area-1
add disabled=no instance=v3 name=ospf-area-2
/ip address
add address=192.168.144.22/30 interface=ether1 network=192.168.144.20
add address=192.168.144.25/30 interface=ether2 network=192.168.144.24
/ip dhcp-client
add interface=ether1
/ipv6 address
add address=2001:20:23:13:7::2/80 advertise=no interface=ether1
add address=2001:20:23:13:8::1/80 advertise=no interface=ether2
/routing ospf interface-template
add area=ospf-area-2 disabled=no interfaces=ether1,ether2
add area=ospf-area-1 disabled=no interfaces=ether1,ether2
