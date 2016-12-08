# **Configuring sipXcom DevOps style**

After you install your sipXcom servers (DevOps style of course), the next step will be to configure them. The traditional method of configuring a single server or cluster of servers is to run sipxecs-setup on primary node, finish installation then go to Admin UI where you need to add your secondary servers (if you are running a cluster) and then finally after that you will need to go on each server CLI and run sipxecs-setup.

Let’s have a look on how we can do this in devops style:

**Step 1: Ansible needs to gain root access to your servers**

On your lab setup run, let’s first login and then create a folder (if you are logged in as root this would then be /root/Configuring_SipXcom_Cluster_DevOps) where we should keep all Proof of Concept (PoC) files:

```
mkdir Configuring_SipXcom_Cluster_DevOps
cd Configuring_SipXcom_Cluster_DevOps
```

Next we need to make sure that ansible have root access to all of the managed servers:

```
ssh-copy-id root@10.3.0.150
ssh-copy-id root@10.3.0.151
ssh-copy-id root@10.3.0.152
```

(Of course you will need to change those IP’s with your own)


Then create ansible.cfg and inventory.ini with the above hosts. Here’s what those files should look like:

```
cat ansible.cfg
[defaults]
hostfile = inventory.ini
remote_user = root
```

```
cat inventory.ini
[uc1]
10.3.0.150
[uc2]
10.3.0.151
[uc3]
10.3.0.152
```


**Step 2: Create a shell script used for primary server configuration**


First command will be to instruct sipxecs-setup script to run in **headless mode** by providing the following attributes:

```
sipxecs-setup --noui --sip_domain mihai.local --sip_realm mihai.local --net_domain mihai.local --net_host uc1
```

Note: You can run **sipxecs-setup --help** to get all the available attributes


After the primary was configured we will need to add the secondaries in PostgresSQL, this step is required so that no UI interaction will be required.


Note that this will work just for these 3 machines, if you will want to add new machines to your cluster you need to invest some time on learning how to create stored procedures in psql since I’ve hard-coded location_id’s (change below entries to your needs)

```
psql -U postgres SIPXCONFIG << EOF
INSERT INTO location (location_id, name, fqdn, ip_address, password, primary_location, registered, use_stun, stun_address, stun_interval, public_address, public_port, start_rtp_port, stop_rtp_port, branch_id, public_tls_port, state, last_attempt, call_traffic, replicate_config, region_id) VALUES (2, 'Secondary', 'uc2.mihai.local', '10.3.0.151', 'GwGh1111', false, false,false, 'stun.ezuce.com', 60, NULL, 5060, 30000, 31000,NULL, 5061, 'UNINITIALIZED','2016-06-22 21:05:36.552', true, true, NULL);
INSERT INTO location (location_id, name, fqdn, ip_address, password, primary_location, registered, use_stun, stun_address, stun_interval, public_address, public_port, start_rtp_port, stop_rtp_port, branch_id, public_tls_port, state, last_attempt, call_traffic, replicate_config, region_id) VALUES (3, 'Tertiary', 'uc3.mihai.local', '10.3.0.152', 'GwGh1111', false, false,false, 'stun.ezuce.com', 60, NULL, 5060, 30000, 31000,NULL, 5061, 'UNINITIALIZED','2016-06-22 21:05:36.552', true, true, NULL);
EOF
```

Replace each ‘*.mihai.local’ with your server names and ‘10.3.0.x’ with your IP addresses.


**Step 3: Create Ansible playbook that will be used to automatically configure this cluster**


Create a ‘.../Configuring_SipXcom_Cluster_DevOps/configure.yml’ file that looks like the following:

```
cat configure.yml
---
- hosts: uc1
  tasks:
    - name: Configuring Primary server
      script: configure_master.sh

- hosts: uc2
  tasks:
  - name: Configuring secondary server
    shell: sipxecs-setup --noui --master_address 10.3.0.150 --location_id 2

- hosts: uc3
  tasks:
  - name: Configuring third server
    shell: sipxecs-setup --noui --master_address 10.3.0.150 --location_id 3
```



script: configure_master.sh - directive will execute the above script on primary node that will set it up as master node and will add needed psql entries


From this moment on, all we need to run to get a functional cluster will be a remote ansible shell command which will configure uc2 and uc3 as slaves that gets their configuration from the node with the IP of 10.3.0.150 (the cluster’s master server).


At the end of the project our folder will have all these files in the same path:

```
[mcostache@localhost Configuring_SipXcom_Cluster_DevOps]$ ll
total 24
-rw-rw-r--. 1 mcostache mcostache   55 Aug 30 10:55 ansible.cfg
-rw-rw-r--. 1 mcostache mcostache 1412 Aug 30 15:22 configure_master.sh
-rw-rw-r--. 1 mcostache mcostache  375 Aug 30 14:23 configure.yml
-rw-rw-r--. 1 mcostache mcostache   51 Aug 30 10:54 inventory.ini
-rw-rw-r--. 1 mcostache mcostache   37 Aug 30 15:03 README.md
```


**Step 4. Execute ansible-playbook from the path**

```
[mcostache@localhost Configuring_SipXcom_Cluster_DevOps]$ pwd
/home/mcostache/PROIECTELE_MELE/Configuring_SipXcom_Cluster_DevOps


[mcostache@localhost Configuring_SipXcom_Cluster_DevOps]$ ansible-playbook configure.yml


PLAY [uc1] *********************************************************************


TASK [setup] *******************************************************************
ok: [10.3.0.150]


TASK [Configuring Primary server] **********************************************
```

