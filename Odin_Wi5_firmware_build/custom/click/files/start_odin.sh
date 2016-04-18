#/bin/sh

CTLIP=192.168.1.2
DPID=0000000000000112
DPPORTS="eth1"
CLICK=/usr/bin/minclick
AGENT=/usr/share/click/agent.click
#CLICK=/usr/bin/click

MYIP=`ifconfig br-lan | awk '/inet addr/{gsub(/.*:/,"",$2);print $2}'`
MYMAC=`ifconfig br-lan | awk '/HWaddr/ {print $5}'`

stop_openvswitch() {
  echo "Stopping OpenvSwitch"
  start-stop-daemon -q -K -p /var/run/ovsdb-server.pid
  start-stop-daemon -q -K -p /var/run/ovs-vswitchd.pid
  rm -f /tmp/openvswitch/conf.db /tmp/openvswitch/conf.db.~lock~
}

start_openvswitch() {
  echo "Starting OpenvSwitch"
  mkdir -p /tmp/openvswitch
  ovsdb-tool create /tmp/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema
  ovsdb-server /tmp/openvswitch/conf.db --remote=ptcp:9999:$MYIP --pidfile=/var/run/ovsdb-server.pid --detach
  sleep 5
  ovs-vswitchd tcp:$MYIP:9999 --pidfile=/var/run/ovs-vswitchd.pid --overwrite-pidfile --detach 
  ovs-vsctl --db=tcp:$MYIP:9999 add-br br0
  for port in $DPPORTS ; do
    if ! grep -q up /sys/class/net/$port/operstate; then
      ifconfig $port up
    fi
    if ! ovs-vsctl --db=tcp:$MYIP:9999 list-ports br0 | grep -q $port; then
      ovs-vsctl --db=tcp:$MYIP:9999 add-port br0 $port
      ovs-vsctl --db=tcp:$MYIP:9999 set bridge br0 other-config:datapath-id=$DPID
      ovs-vsctl --db=tcp:$MYIP:9999 set-controller br0 tcp:$CTLIP:6633
      ovs-vsctl --db=tcp:$MYIP:9999 set-fail-mode br0 secure
    fi
  done
}

stop_monitoring() {
  echo "Stopping monitor mode"
  ifconfig mon0 down
  ifconfig wlan0 up
}

start_monitoring() {
  echo "Starting monitor mode"
  ifconfig wlan0 down
  if [ ! -d /sys/class/net/mon0 ]; then
    iw phy phy0 interface add mon0 type monitor
  fi
  ifconfig mon0 up
  iw dev wlan0 set channel 6
}
 
stop_odinagent() {
  echo "Stopping Odin agent"
  killall -q `basename $CLICK`
}

start_odinagent() {
  echo "Starting Odin agent"
  sed -r -e '/^odinagent ::/s/([0-9]{1,3}\.){3}[0-9]{1,3}'/$MYIP/ \
         -e '/^odinagent ::/s/[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}'/$MYMAC/ \
         -e '/^odinsocket ::/s/([0-9]{1,3}\.){3}[0-9]{1,3}'/$CTLIP/ \
         -e '/^arp_resp ::/s/([0-9]{1,3}\.){3}[0-9]{1,3}'/$MYIP/ \
         -e '/^arp_resp ::/s/[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}:[a-zA-Z0-9]{2}'/$MYMAC/ \
    $AGENT > /tmp/agent.click
  /usr/bin/click-align /tmp/agent.click > /tmp/agent.aligned
  $CLICK /tmp/agent.aligned &
  sleep 3
  ifconfig ap up
  ovs-vsctl --db=tcp:$MYIP:9999 add-port br0 ap
}

stop_odinagent
stop_monitoring
stop_openvswitch
start_openvswitch
start_monitoring
start_odinagent

