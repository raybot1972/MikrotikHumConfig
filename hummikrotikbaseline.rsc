# --- Interfaces & Bridge ---
/interface bridge
add name=bridge protocol-mode=none admin-mac=4C:5E:0C:EB:6F:25 auto-mac=no comment=defconf
/interface bridge port
add bridge=bridge interface=ether2 comment=defconf
add bridge=bridge interface=ether3 comment=defconf
add bridge=bridge interface=ether4 comment=defconf
add bridge=bridge interface=ether5 comment=defconf
add bridge=bridge interface=wlan1 comment=defconf
/interface list
add name=WAN comment=defconf
add name=LAN comment=defconf
/interface list member
add interface=bridge list=LAN comment=defconf
add interface=ether5 list=WAN

# --- Wireless ---
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
add name=humantouchp_profile mode=dynamic-keys authentication-types=wpa2-psk wpa2-pre-shared-key=mannytanitaraymond00
/interface wireless
set [ find default-name=wlan1 ] ssid=HUMANTOUCHP mode=ap-bridge band=2ghz-b/g/n channel-width=20/40mhz-XX \
    security-profile=humantouchp_profile comment="Paratus Wifi Bridged"

# --- IP & DHCP ---
/ip address
add address=192.168.1.250/24 interface=bridge network=192.168.1.0
/ip pool
add name=lan_pool ranges=192.168.1.149-192.168.1.199
/ip dhcp-server
add name=dhcp_hum interface=bridge address-pool=lan_pool lease-time=1h
/ip dhcp-server network
add address=192.168.1.0/24 gateway=192.168.1.250 dns-server=192.168.1.250 domain=home

# --- DNS ---
/ip dns
set allow-remote-requests=yes servers=192.168.1.116
/ip dns static
add name=relay.rustdesk.com address=104.21.12.233
add name=relay.rustdesk.com address=172.67.10.10

# --- Firewall Filter ---
/ip firewall filter
add chain=input connection-state=established,related,untracked action=accept comment="accept established,related,untracked"
add chain=input connection-state=invalid action=drop comment="drop invalid"
add chain=input protocol=icmp action=accept comment="accept ICMP"
add chain=input dst-address=127.0.0.1 action=accept comment="accept loopback"
add chain=input in-interface-list=!LAN action=drop comment="drop all not from LAN"
add chain=forward connection-state=established,related,untracked action=accept comment="accept established,related,untracked"
add chain=forward connection-state=invalid action=drop comment="drop invalid"
add chain=forward connection-nat-state=!dstnat connection-state=new in-interface-list=WAN action=drop comment="drop WAN not dst-nated"
add chain=forward connection-state=new dst-port=21112-21119 protocol=tcp action=accept comment="RustDesk outbound TCP"
add chain=forward connection-state=new dst-port=21112-21119 protocol=udp action=accept comment="RustDesk outbound UDP"
add chain=forward dst-port=1900 protocol=udp action=accept comment="Allow SSDP for Chromecast"

# --- NAT ---
/ip firewall nat
add chain=srcnat out-interface-list=WAN action=masquerade comment="masquerade LAN to WAN"
add chain=dstnat dst-port=21115 protocol=tcp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbs 21115"
add chain=dstnat dst-port=21116 protocol=tcp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbs 21116 TCP"
add chain=dstnat dst-port=21116 protocol=udp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbs 21116 UDP"
add chain=dstnat dst-port=21117 protocol=tcp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbr 21117"
add chain=dstnat dst-port=21118 protocol=tcp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbs 21118"
add chain=dstnat dst-port=21119 protocol=tcp action=dst-nat to-addresses=192.168.1.120 comment="RustDesk hbbr 21119"

# --- Mangle (for queues) ---
/ip firewall mangle
add chain=prerouting src-address=192.168.1.120 action=mark-connection new-connection-mark=conn_acelin_down comment="Mark conn acelin download"
add chain=prerouting connection-mark=conn_acelin_down action=mark-packet new-packet-mark=pkt_acelin_down comment="Mark pkt acelin download"
add chain=postrouting dst-address=192.168.1.120 action=mark-connection new-connection-mark=conn_acelin_up comment="Mark conn acelin upload"
add chain=postrouting connection-mark=conn_acelin_up action=mark-packet new-packet-mark=pkt_acelin_up comment="Mark pkt acelin upload"
add chain=prerouting src-address=192.168.1.2 action=mark-connection new-connection-mark=conn_mana25_down comment="Mark conn mana25 download"
add chain=prerouting connection-mark=conn_mana25_down action=mark-packet new-packet-mark=pkt_mana25_down comment="Mark pkt mana25 download"
add chain=postrouting dst-address=192.168.1.2 action=mark-connection new-connection-mark=conn_mana25_up comment="Mark conn mana25 upload"
add chain=postrouting connection-mark=conn_mana25_up action=mark-packet new-packet-mark=pkt_mana25_up comment="Mark pkt mana25 upload"

# --- Queue Tree ---
/queue tree
add name=acelin_down parent=global packet-mark=pkt_acelin_down max-limit=5M burst-limit=6M burst-threshold=5M burst-time=30s priority=5 queue=default
add name=acelin_up parent=global packet-mark=pkt_acelin_up max-limit=5M burst-limit=6M burst-threshold=5M burst-time=30s priority=5 queue=default
add name=mana25_down parent=global packet-mark=pkt_mana25_down max-limit=5M burst-limit=6M burst-threshold=5M burst-time=30s priority=5 queue=default
add name=mana25_up parent=global packet-mark=pkt_mana25_up max-limit=5M burst-limit=6M burst-threshold=5M burst-time=30s priority=5 queue=default

# --- DHCP Reservations ---
/ip dhcp-server lease
add address=192.168.1.2   mac-address=CA:32:8D:06:74:C0 comment="Manny A25 (mana25)" server=dhcp_hum
add address=192.168.1.3   mac-address=C0:3F:D5:60:71:2C comment="Intelnuk Manny (nukman)" server=dhcp_hum
add address=192.168.1.4   mac-address=84:47:09:5C:62:0F comment="NucBox_M5PLUS (nucm5p)" server=dhcp_hum
add address=192.168.1.5   mac-address=84:47:09:47:60:27 comment="NucBox_G6 (nucbg6)" server=dhcp_hum
add address=192.168.1.8   mac-address=70:F1:A1:66:50:CB comment="vostro3500m (vostoe)" server=dhcp_hum
add address=192.168.1.10  mac-address=E4:5F:01:C8:E0:07 comment="Marine Traffic Raspberry PI (martra)" server=dhcp_hum
add address=192.168.1.12  mac-address=00:0E:C6:29:5E:3D comment="Acer-Apire-Go-15 (aceray)" server=dhcp_hum
add address=192.168.1.13  mac-address=12:48:E4:DC:61:AE comment="Lenovo-Tab-M11 (lenm11)" server=dhcp_hum
add address=192.168.1.74  mac-address=BC:24:11:CD:1E:6D comment="Uptimekuma Server (uptime)" server=dhcp_hum
add address=192.168.1.75  mac-address=BC:24:11:BE:9A:0A comment="Debian Docker Server (debdoc)" server=dhcp_hum
add address=192.168.1.77  mac-address=BC:24:11:42:A7:2B comment="Alpine Server (alpine)" server=dhcp_hum
add address=192.168.1.82  mac-address=BC:24:11:61:EA:57 comment="Kimai Time Keeping Server (kimai)" server=dhcp_hum
add address=192.168.1.87  mac-address=BC:24:11:40:52:10 comment="Stirling-pdf Server (stirli)" server=dhcp_hum
add address=192.168.1.90  mac-address=BC:24:11:C0:03:5D comment="Home File Server (filser)" server=dhcp_hum
add address=192.168.1.99  mac-address=BC:24:11:75:6A:BF comment="n8n Server (n8n)" server=dhcp_hum
add address=192.168.1.100 mac-address=F8:BC:12:73:E6:02 comment="Proxmox Virtual Server (proxmo)" server=dhcp_hum
add address=192.168.1.103 mac-address=BC:24:11:83:E8:9A comment="Beszel Monitor Server (beszel)" server=dhcp_hum
add address=192.168.1.116 mac-address=BC:24:11:30:8A:FF comment="Technitiumdns DNS Server (techni)" server=dhcp_hum
add address=192.168.1.120 mac-address=BC:24:11:AF:C7:D4 comment="RustDesk Server (rustde)" server=dhcp_hum
add address=192.168.1.126 mac-address=BC:24:11:B6:48:0B comment="Vikuna Server" server=dhcp_hum
add address=192.168.1.128 mac-address=BC:24:11:D6:AC:25 comment="BentoPDF Server" server=dhcp_hum
add address=192.168.1.249 mac-address=E0:28:6D:96:AA:28 comment="Fritz Box AP (fritzb)" server=dhcp_hum
# --- Routing ---
/ip route
add distance=1 gateway=192.168.1.1

# --- UPNP ---
/ip upnp set enabled=yes
/ip upnp interfaces
add interface=bridge type=internal
add interface=ether1 type=external

# --- System ---
/system clock
set time-zone-name=Africa/Windhoek

# --- Graphing ---
/tool graphing interface
add interface=wlan1
add interface=bridge
/tool graphing queue
add allow-target=no

# --- MAC Server & Winbox ---
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN

# --- Neighbor Discovery ---
/ip neighbor discovery-settings
set discover-interface-list=LAN