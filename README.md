# Oracle home management with Ansible

You shouldn't patch Oracle home that is used to run a database, just install a new one, with the correct patch list and then quickly stop instances running from old home and start instances from the newly installed home.
This strategy greatly reduces the time needed for Oracle database patching and also gives you a quick and safe way to "roll back", just simply start the instance using old home again.

If you name your database homes in a standard and predictable way, then you will also remove another database home management difficulties - how to know what patches are actually installed in a given home and a possibility that the same home name in different hosts/clusters could have different patches installed! 

## How to implement this strategy in a real world?

Golden Images are a popular option, that DBA will install and prepare a golden copy of database home that will then be distributed to database hosts/clusters.
This also means actually preparing these images, cleaning them and storing them. Different images for RAC and non-RAC.

Another option, that this repository is using, is just automate database home installation and take out any human action from it and manage it over large/many clusters in your environment. A new home will just be a code, version controlled code. Automation will take care of the rest.

Features of this repository:
* Oracle home configurations become code
* Runs over any number of clusters or single hosts, with same configuration
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

The following will install/deinstall Oracle homes on hostgroup non-prod that contains multiple clusters.
This is intended to be run from Jenkins, triggered by push to git release branch.

```
ansible-playbook -e targetgroup=non-prod -u ansible manage-db-homes.yml
```

## Main configuration files

| Config file | Purpose |
| --- | --- |
| roles/oracle-meta/defaults/main.yml | This file describes the Oracle homes and what they contain |
| group_vars/all/rdbms_homes.yml | This file defines "flavours of clusters" and what homes each flavour must have and what homes removed, so each individual cluster can just say give me the "site" package |
| group_vars/all/installer_location.yml | Where database installer and patch files are located (and unzipped) |
