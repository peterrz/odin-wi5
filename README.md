Odin
====

Odin is an SDN framework programmable enterprise WLANs. It provides
a platform for developing typical enterprise WLAN services such as
mobility management, load balancing, seamless handover, etc. as "network applications".

It was initially developed by Lalith Shuresh (https://github.com/lalithsuresh).

This is a fork with some improvements, being added within the H2020 Wi-5 (What to do With the Wi-Fi Wild West) Project (see http://www.wi5.eu/)

You have more information in this wiki: https://github.com/Wi5/odin-wi5/wiki

Requirements
------------

For the agent/AP:

- An OpenWrt wireless router (https://openwrt.org/)
- Click Modular Router (https://github.com/kohler/click) with the Odin elements added (https://github.com/Wi5/odin-agent).
- Open vSwitch (an Openflow implementation running in the AP).
- An ath9k driver-based Wi-Fi card. You should first patch the driver with the
patch provided in https://github.com/Wi5/odin-wi5/tree/master/odin-patch-driver-ath9k

- You may find some help and utilities here: https://github.com/fgg89

Terminology
-----------

- **Odin Controller**: The entity (a PC) who controls the whole system. It
is an application which runs on top of Floodlight Openflow controller.
- **Odin Agent** / **Access Point** / **AP**: It runs Click Modular Router with Odin elements,
and communicates with the Odin Controller in two ways: through a control socket,
and through Openflow protocol.
- **STA** / **Client**: The terminals that connect to the APs.
- **LVAP**: A light virtual Access Point, which is in charge of each STA
connected to an Odin AP. It is a 4-tuple including a) the STA MAC address
(the real MAC); b) its static IP address (the IP of the wireless interface
of the STA); c) a BSSID that the AP will use for communicating with this
single STA; and d) the SSID that the AP will use for communicating with this
single STA.

This is a scheme of these elements:

```

      Access Point                                       Controller
+-------------------------------+                        +------------------+
| +---------------------------+ |                        | +-----------+    |
| |+--------+ +------+ +-----+| |                        | |Floodligh  |    |
| || ap TAP | | LOCAL| |eth1 || |   openflow TCP 6633    | |controller |    |
| |+-------2+ +------+ +----1+| |   openflow TCP 6655    | +-----------+    |
| |  |   ^    Openvswitch br0 | |  <----------------->   |    ^             |
| +--|---|--------------------+ |                        |    |             |
|    v   |                      |   odin UDP skt 2819    |    v             |
| +-----------------+           |   ----------------->   | +--------------+ |
| | Click +--------+|           |  click controlskt 6777 | | Odin         | |
| |       |odin ag ||           |  click chatterskt 6778 | | Master       | |
| |       +--------+|           |  <---------------->    | +--------------+ |
| +-----------------+           |                        |                  |
|    |   ^                      |                        +------------------+
|    v   |                      |
|  +--------+                   |       Ethernet
+--| mon0   |-------------------+
   +--------+      
     |                         Protocol between Odin master and agents:
     |                           - Click controlsocket port 6777:
     |  <- -WiFi- >  |              - ADD_LVAP
                     |              - REMOVE_LVAP
                     |              - QUERY_STATS
                +-----+             - ADD_SUBSCRIPTION
                |     |             
                | STA |          - Odin UDP socket port 2819:
                |     |             - RECVD_PROBE_REQUEST
                +-----+             - PING
                                    - PUBLISH
```

Download and installation
-------------------------

**Odin Controller**

Running Odin implies setting up the Odin Controller and Odin Agents.

If you cloned Odin from the git repository, pull the individual submodules:

```
  $: git clone https://github.com/Wi5/odin-wi5-controller
```

To build the Odin Controller (which is built as an application on top of Floodlight),
do the following:

```
  $: cd odin-wi5-controller
  $: ant
```

You should find `floodlight.jar` inside `target/`

**Odin Agent**

You have an automated script for generating the .bin file for the AP here: https://github.com/Wi5/odin-wi5/tree/master/Odin_Wi5_firmware_build

Before building the agent, apply the patch in `odin-driver-patches` 
(https://github.com/Wi5/odin-wi5/tree/master/odin-patch-driver-ath9k) to your
Linux kernel ath9k driver code.

To build the agent, copy the files in `odin-agent/src/` to your Click source's
`/elements/local` folder, then build Click:

```
  $: cd odin-agent
  $: cp src/* <click-folder>/elements/local
```

Now build Click using your cross compiler. Don't forget to pass the 
`--enable-local` flag to Click's configure script.

Generate a Click file for the agent, using your preferred values for the
options. Use this Python script: https://github.com/Wi5/odin-wi5-agent/blob/master/agent-click-file-gen.py 
and follow the instructions there.


Running Odin
------------

Controller
----------

The master is to be run on a server that has IP reachability to all the
APs in the system.
The master expects the following configuration parameters to be set in the
floodlight configuration file 
`~/odin-master/src/main/resources/floodlightdefault.properties`

This is an example of the content of `floodlightdefault.properties`:
(you can find it here: https://github.com/Wi5/odin-master/blob/odin/src/main/resources/floodlightdefault.properties)
```
floodlight.modules = net.floodlightcontroller.storage.memory.MemoryStorageSource,\
net.floodlightcontroller.staticflowentry.StaticFlowEntryPusher,\
net.floodlightcontroller.learningswitch.LearningSwitch,\
net.floodlightcontroller.jython.JythonDebugInterface,\
net.floodlightcontroller.counter.CounterStore,\
net.floodlightcontroller.perfmon.PktInProcessingTime,\
net.floodlightcontroller.ui.web.StaticWebRoutable,\
net.floodlightcontroller.odin.master.OdinMaster
net.floodlightcontroller.restserver.RestApiServer.port = 8080
net.floodlightcontroller.core.FloodlightProvider.openflowport = 6633
net.floodlightcontroller.jython.JythonDebugInterface.port = 6655
net.floodlightcontroller.odin.master.OdinMaster.masterPort = 2819
net.floodlightcontroller.odin.master.OdinMaster.poolFile = poolfile
net.floodlightcontroller.odin.master.OdinMaster.clientList = odin_client_list
```
The meaning of some of the lines is:

**Odin Java module**

Charge the odin Java module:

* `net.floodlightcontroller.odin.master.OdinMaster`


**Poolfile**

Tell Odin where the file `poolfile` is:

* `net.floodlightcontroller.odin.master.OdinMaster.poolFile = poolfile`


This should point to a pool file (in `~/odin-master/`), which are essentially slices.

By default the `poolfile` should be in the `~/odin-master/` directory. You can also 
place it in other way, but then you should provide the path.

An example of the `poolfile` content is as follows:
(you can find it here: https://github.com/Wi5/odin-master/blob/odin/poolfile)
```
  # Pool-1
  NAME pool-1
  NODES 192.168.1.5 192.168.1.6
  NETWORKS odin-mobility-network
  APPLICATIONS net.floodlightcontroller.odin.applications.OdinMobilityManager

  # Pool-2
  NAME pool-2
  NODES 192.168.1.7 192.168.1.8 192.168.1.9
  NETWORKS odin-guest-network
  APPLICATIONS net.floodlightcontroller.odin.applications.SimpleLoadBalancer
```

Each pool is defined by a name, a list of IP addresses of physical APs (NODES),
the list of SSIDs or NETWORKS to be announced, and a list of applications
that operate on that pool.


**Odin client list (only required when DHCP is not used)**

If DHCP is not used, then the Odin controller is not able to hear the DHCP ACK
packets, so it is not aware of the IPs of the clients.

Therefore, if you are not using DHCP, then:

- assign a static IP to each STA. These IPs must be in the same subnet as the 
wireless interface of the AP.

- you need to specify the STAs' details in a file pointed to by this property 
(ClientList). So add to the `floodlightdefault.properties` file the next line:

* `net.floodlightcontroller.odin.master.OdinMaster.clientList = odin_client_list`


An example odin_client_list file looks as follows:
(you can find it here: https://github.com/Wi5/odin-master/blob/odin/odin_client_list)
```
74:F0:6D:20:D4:74 192.168.1.11 00:1B:B3:67:6B:11 odin-unizar-1
20:68:3F:60:2A:F2 192.168.1.12 00:1B:B3:67:6B:12 odin-unizar-2
80:18:7C:EB:F0:2E 192.168.1.13 00:1B:B3:67:6B:13 odin-unizar-3

```

Each row represents a STA:
- MAC address (the MAC of the physical interface)
- Static IP address (the IP of the wireless interface of the STA)
- its LVAP's BSSID. You can invent it
- the SSID that its LVAP will announce

(If you add white lines in the end of this file, you will get an error from Odin).

Please note: If you add the MAC of a device in this file, then it will not obtain
an IP address with DHCP, so you will have to set it manually.


**Port for Odin messages**

If you want to change the port used for the communication between Odin controller
and Odin agents, you can add this line to the `floodlightdefault.properties` file:

* `net.floodlightcontroller.odin.master.OdinMaster.masterPort = 2819`

Another parameter you can set is `idleLvapTimeout` (see the source code of 
`OdinMaster.java`).


To run the master:

```
  $: java -jar floodlight.jar
```

If you want to specify the location of the configuration file, run:

```
  $: java -jar floodlight.jar -cf configfile
```
An example:
```
  ~/odin-master# java -jar ./target/floodlight.jar -cf ./src/main/resources/floodlightdefault.properties
```

Agent: Prepare the wireless interface
--------------------------------------

Instantiate a monitor device:

```
  # If on OpenWRT
  $: ifconfig wlan0 down
  $: iw phy phy0 interface add mon0 type monitor
  $: iw dev wlan0 set channel <required-channel>  # the same channel specified in agent.click
  $: ifconfig mon0 up
  $: ifconfig wlan0 up
```

Agent: Automated scripts (Option 1)
-----------------------------------

If you want, you can use some scripts in order to automate the next steps (run OpenvSwitch and
start Click):

https://github.com/Wi5/odin-agent/tree/master/scripts_start_ap_odin

Run first `script_start_ovs.sh` and then `script_start_click.sh`.

The scripts have been inspired in https://gist.github.com/marciolm/9f0ab13b877372d08e8f


Agent: Run OpenvSwitch manually (Option 2)
------------------------------------------

You have to instantiate Open vSwitch and have it connected to the
Floodlight controller from above. For that, do the next steps:

Start the Openvswitch service:

```
  $: /etc/init.d/openvswitch start
```

Using Openvswitch, add a bridge named `br0`.

First remove it (if it exists):
 
```
  $: ovs-vsctl del-br br0
```

Add the switch:

```
  $: ovs-vsctl add-br br0
```

Connect the bridge to an Openflow controller:

```
  $: ovs-vsctl set-controller br0 tcp:192.168.1.2
```

Add the interfaces of the internal network to the bridge `br0`. You 
have to add (at least) the interfaces that connect the AP with the 
controller, the DHCP server and the rest of the network. There is no problem
if you add all the interfaces of the AP:

```
  $: ovs-vsctl add-port br0 eth1.1
  $: ovs-vsctl add-port br0 eth1.2
  $: ovs-vsctl add-port br0 eth1.3
  $: ovs-vsctl add-port br0 eth1.4
```

If you have previously ran Odin in this AP, remove the interface `ap`:

```
  $: ovs-vsctl del-port br0 ap
```

Agent: Start Click Modular Router manually (Option 2)
-----------------------------------------------------

Move the agent.click file generated through the click file generator to
the AP, and run the following (this first aligns the agent configuration file
and then runs Click):

```
  $: click-align agent.click | click &
```

Another option is to algin the `agent.click` file in the machine where you are
generating it, and then just run:

```
  $: click agent.click &
```

(Make sure `agent.click` specifies the same channel as being used by the monitor
device.)

As soon as Click starts running, an `ap` interface will appear. 

Switch on the `ap` interface:
```
  $: ifconfig ap up
```

Add the interface to the bridge
```
  $: ovs-vsctl add-port br0 ap
```

You can use `ovs-vsctl list-ports br0` to make sure `ap` and the other interfaces 
are included in `br0`.


Station: Connect to Odin
-------------------------

At this point, you should be able to connect from a STA and ping. You should see
an ESSID created by Odin in the STA. You can connect in Linux using:

```
  $: iwconfig wlan0 essid odin-ssid-1
```



References
----------

The system is described in the following Masters' thesis:
http://lalithsuresh.files.wordpress.com/2011/04/lalith-thesis.pdf

You may find some information in this article:
https://www.usenix.org/system/files/conference/atc14/atc14-paper-schulz_zander.pdf

And this is a presentation:
https://www.usenix.org/conference/atc14/technical-sessions/presentation/schulz-zandery
