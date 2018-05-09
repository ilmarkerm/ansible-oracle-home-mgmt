# Oracle home management with Ansible

You shouldn't patch Oracle home that is used to run a database, just install a new one, with the correct patch list and then quickly stop instances running from old home and start instances from the newly installed home.
This strategy greatly reduces the time needed for Oracle database patching and also gives you a quick and safe way to "roll back", just simply start the instance using old home again.

**Never patch existing Oracle home, even when you just need to apply tiny one-off patch. Always install a new home and eventually remove the old one.**

If you name your database homes in a standard and predictable way, then you will also remove another database home management difficulties - how to know what patches are actually installed in a given home and a possibility that the same home name in different hosts/clusters could have different patches installed!

## How to implement this strategy in a real world?

Golden Images are a popular option, that DBA will install and prepare a golden copy of database home that will then be distributed to database hosts/clusters.
This also means actually preparing these images, cleaning them and storing them. Different images for RAC and non-RAC.

Another option, that this repository is using, is just automate database home installation and take out any human action from it and manage it over large/many clusters in your environment. A new home will just be a code, version controlled code. Automation will take care of the rest.

Features of this repository:
* Oracle home configurations become code
* Runs over any number of clusters or single hosts, with same configuration in parallel
* Maintain list of homes or flavours of homes each cluster/single host is having installed or what need to be removed
* Oracle Grid infrastructure or Oracle Restart installation is required
* Fully automated, up to the point that you have a job in Jenkins that is triggered by push to version control system (git)
* Home description in Ansible variable file also servers as documentation
* All tasks are idempotent, so you can execute playbook multiple times. If the servers already have the desired state, nothing will be changed

Ideal workflow to install a new home:
* Describe in Ansible variable file the home name, base installer location and list of patches needed
* Attach home name to clusters/hosts in Ansible files
* Commit and push to git
* Go through your typical git workflows to push the change into release branch, create pull requests, have them reviewed by peers, merge pull request into release branch
* Job in jenkins triggers on push to release branch in git and then executes ansible playbook in target/all hosts

## How to execute

First install all used roles from Ansible Galaxy.

```
ansible-galaxy install ilmarkerm.oracle-home-management
```

The following will install/deinstall Oracle homes on hostgroup non-prod that contains multiple clusters.
This is intended to be run from Jenkins, triggered by push to git release branch.

Login user (ansible in this example) must have sudo privileges to database owner (oracle) and root.

```
ansible-playbook -e targetgroup=non-prod -u ansible manage-db-homes.yml
```

## Main configuration files

| Config file | Purpose |
| --- | --- |
| roles/oracle-meta/defaults/main.yml | This file describes the Oracle homes and what they contain |
| group_vars/all/rdbms_homes.yml | This file defines "flavours of clusters" and what homes each flavour must have and what homes removed, so each individual cluster can just say give me the "site" package. This is just a helper, it is not used directly. |
| group_vars/all/installer_location.yml | Where database installer and patch files are located (and unzipped) |
| group_vars/cluster_name/cluster.yml | Here you can define, if this cluster is RAC or not. If RAC, then you also need to define the master_host, where the initial installation is actually performed. |
| group_vars/cluster_name/rdbms_homes.yml | Here you can define a list what homes should be present in the cluster and what homes should be removed. Example refers to the main list defined in group_vars/all/rdbms_homes.yml |
| hosts | Ansible inventory file, define your clusters/hosts here. Each cluster must be ansible hostgroup and all cluster nodes defined. |

## Shared installation folder

System requires that each host mounts a shared installation folder that contains Oracle database installation media and all the required patch folders. All unzipped.
Locations are defined in **group_vars/all/installer_location.yml**, all locations under **roles/oracle-meta/defaults/main.yml** are relative to these locations.

For the examples here, the installation folder structure looks like this:

```
/nfs/install/base_installers/
├── 11.2.0.4
│   ├── database
│   │   ├── install
│   │   ├── readme.html
│   │   ├── response
│   │   ├── rpm
│   │   ├── runInstaller
│   │   ├── sshsetup
│   │   ├── stage
│   │   └── welcome.html
├── 12.1.0.2
│   ├── database
│   │   ├── install
│   │   ├── response
│   │   ├── rpm
│   │   ├── runInstaller
│   │   ├── sshsetup
│   │   ├── stage
│   │   └── welcome.html
├── 12.2.0.1
│   ├── database
│   │   ├── install
│   │   ├── response
│   │   ├── rpm
│   │   ├── runInstaller
│   │   ├── sshsetup
│   │   ├── stage
│   │   └── welcome.html

/nfs/install/patch/
├── 2018-04
│   ├── 22761995
│   │   ├── etc
│   │   ├── files
│   │   ├── online
│   │   └── README.txt
│   ├── 22761995.psu
│   │   ├── etc
│   │   ├── files
│   │   ├── online
│   │   └── README.txt
│   ├── 23589471
│   │   ├── etc
│   │   ├── files
│   │   └── README.txt
│   ├── 27338041
│   │   ├── 19769480
│   │   ├── 20299023
│   │   ├── 20831110
│   │   ├── 21359755
│   │   ├── 21948354
│   │   ├── 22291127
│   │   ├── 23054246
│   │   ├── 24006101
│   │   ├── 24732082
│   │   ├── 25171037
│   │   ├── 25755742
│   │   ├── 26609783
│   │   ├── 26713565
│   │   ├── 26925311
│   │   ├── 27338041
│   │   ├── README.html
│   │   └── README.txt
├── p6880880_112000_Linux-x86-64.zip
├── p6880880_122010_Linux-x86-64_old.zip
└── p6880880_122010_Linux-x86-64.zip
```
