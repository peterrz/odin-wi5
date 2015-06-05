Odin
====

Odin is an SDN framework programmable enterprise WLANs. It provides
a platform for developing typical enterprise WLAN services such as
mobility managers, and load balancers as "network applications".

It was developed by Lalith Shuresh (https://github.com/lalithsuresh).
This is a fork with some improvements.


Requirements
------------

For the agent/AP:

- Click Modular Router with the Odin elements added
(https://github.com/Wi5/odin-agent).
- Open vSwitch (an Openflow implementation running in the AP).
- An ath9k driver based WiFi card. You should first patch it with the
patch provided in https://github.com/lalithsuresh/odin-driver-patches

- You may find some help and utilities here: https://github.com/fgg89

Terminology
-----------

- **Odin Master** / **Controller**: the entity who controls the whole system. It
is an application which runs on top of Floodlight Openflow controller.
- **Odin Agent** / **Access Point** / **AP**: It runs Click Router with Odin elements,
and communicates with the Odin Master in two ways: through a control socket,
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
    +-------------------------+                        +------------------+
    | +---------------------+ |   odin skt UDP 2189    | +------+         |
    | |+--------+       dp0 | |  <---------------->    | |odin  |         |
    | || ap TAP |           | |                        | |master|         |
    | |+--------+           | |   openflow TCP 6633    | +------+         |
    | +--|---^--------------+ |   openflow TCP 6655    |    ^             |
    |    |   |                |  <---------------->    |    |             |
    |    v   |                |                        |    v             |
    | +---------------------+ |                        | +--------------+ |
    | | Click     +--------+| |                        | | Floodlight   | |
    | |           |odin mod|| |                        | | controller   | |
    | |           +--------+| |  click controlskt 6777 | +--------------+ |
    | +---------------------+ |  click chatterskt 6778 |                  |
    |    |   ^                |  <---------------->    +------------------+
    |    v   |                |
    |  +--------+             |       Ethernet
    +--| mon0   |-------------+
       +--------+      
         |
         |
         |  <- -WiFi- >  |
                         |
                         |
                    +-----+
                    |     |
                    | STA |
                    |     |
                    +-----+
```

Building/Installation
---------------------

Running Odin implies setting up the Odin master and Odin agents.

If you cloned Odin from the git repository, pull the individual submodules:

```
  $: git clone http://github.com/lalithsuresh/odin
  $: cd odin
  $: git submodule init
  $: git submodule update
```

To build the master (which is built as an application on top of Floodlight),
do the following:

```
  $: cd odin-master
  $: ant
```

You should find `floodlight.jar` inside `target/`

Before building the agent, apply the patch in `odin-driver-patches` 
(https://github.com/lalithsuresh/odin-driver-patches) to your
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
options:

```
  $: python agent-click-file-gen.py <AP_CHANNEL> <QUEUE_SIZE> \
   <HW_ADDR> <ODIN_MASTER_IP> <ODIN_MASTER_PORT> <DEFUGFS_FILE> \
     > agent.click
```
* `AP_CHANNEL`: it must be the same where mon0 of the AP is placed
* `QUEUE_SIZE`: you can use the size 50
* `HW_ADDR`: the MAC of the wireless interface mon0 of the AP. e.g. E8-DE-27-F7-02-16
* `ODIN_MASTER_IP` is the IP of the openflow controller where Odin master is running
* `ODIN_MASTER_PORT` should be 2819 by default
* `DEBUGFS_FILE` is the path of the bssid_extra file created by the ath9k patch
         it can be e.g. /sys/kernel/debug/ieee80211/phy0/ath9k/bssid_extra'



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

```
floodlight.modules = net.floodlightcontroller.storage.memory.MemoryStorageSource,\
net.floodlightcontroller.staticflowentry.StaticFlowEntryPusher,\
net.floodlightcontroller.forwarding.Forwarding,\
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

```
  # Pool-1
  NAME pool-1
  NODES 172.17.1.13 172.17.1.21 172.17.1.29
  NETWORKS odin-mobility-network
  APPLICATIONS net.floodlightcontroller.odin.applications.OdinMobilityManager

  # Pool-2
  NAME pool-2
  NODES 172.17.1.29 172.17.1.37 172.17.1.45
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

```
  00:16:7f:7e:00:00 172.17.4.2 00:1b:1b:7e:00:00 odin-ssid-1
  00:16:7f:7e:00:01 172.17.4.3 00:1b:1b:7e:00:01 odin-ssid-2
  00:16:7f:7e:00:02 172.17.4.4 00:1b:1b:7e:00:02 odin-ssid-3
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
```

If you want the AP to create its default ESSID, in addition to Odin's one, run this command (not recommended):

```
  $: ifconfig wlan0 up
```

Agent: Automated scripts
------------------------

If you want, you can use some scripts in order to automate the next steps (run OpenvSwitch and
start Click):

https://github.com/Wi5/odin-agent/tree/master/scripts_start_ap_odin

Run first `script_start_ovs.sh` and then `script_start_click.sh`.

The scripts have been inspired in https://gist.github.com/marciolm/9f0ab13b877372d08e8f


Agent: Run OpenvSwitch
-----------------------

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

Agent: Start Click Modular Router
----------------------------------

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
