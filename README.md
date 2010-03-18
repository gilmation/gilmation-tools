# Gilmation Tools

This directory contains the tools used to manage Gilmation servers and the software that runs on them

#### At the present time there are three directories:
* [scripts](#scripts) - Bootstrap scripts and other utilities written in bash.
* [chef](#chef) - System configuration scripts (mainly chef standalone). [Chef Repo](http://github.com/opscode/chef)
* [thor](#thor) - Deployment, backups and storage of the backups in Amazon s3. [Thor Repo](http://github.com/wycats/thor)

## Scripts {#scripts}

The scripts directory contains OS specific scripts that can be used to bootstrap a new instance into a state suitable to run something a bit more "cultured" :-), in our case [Chef](http://github.com/opscode/chef).

##### launch
1. Connect to the given host (arg 2) as the given user (arg 1)
2. Copy over the [setup](#setup) script from this directory
3. Run the [setup](#setup) script

##### setup {#setup}
1. Install the minimum config necesary for a Ruby environment (Ruby and Gems)
2. Use Gems to install ohai and chef (and their dependencies)

##### sshSetup
1. Copy this users public key to the .ssh dir on the given server
2. Setting up the connection so that it won't ask for a password
3. NOTE: only for use by someone who knows what they are doing 

##### iptables
1. Setup the iptables (firewall) for a given ubuntu machine

## Chef {#chef}

The chef directory contains a script [launch](#chef-launch) and the [chef-repo](#chef-repo) directory.  

##### launch {#chef-launch}
1. Installs the chef cookbooks 
2. Installs the $HOME/.ee/gilmation_site_node.json file (whcih contains the configuration necessary for this node)
3. Runs the cookbooks using chef-solo and the gilmation_site_node.json configuration file

### The chef-repo {#chef-repo} directory contains:

##### cookbooks
These are opscode / 37 signals cookbooks that have not been modified and can be overridden by the cookbooks contained in the following directory

##### site-cookbooks
This directory contains the gilmation specific cookbooks that we run in order to configure the standard gilmation.com server.

The recipe that does most of the hard yards here is - gilmation_ee/recipes/default.rb.  This recipe calls the other site specific recipes and as well as installing the software necessary for gilmation.com it also prepares directories so that we can deploy the Expression Engine code easily with Capistrano and administer the Database with [Thor](#thor).  

## Thor {#thor}

Thor is a gem that allows you to write scripts in ruby (like rake) but then install them and have them available to you wherever you are on a given box.  

You can see a list of all the tasks and their descriptions (like Rake or Capistrano), by typing:

    thor -T 

Of interest to us at the moment are the 5 files that we need to install onto the standard gilmation.com server:

##### ee.thor
A list of tasks for deployment, backups and restore of Expression Engine and it's Database.

##### gilmation.thor
A couple of generic methods for use by other gilmation projects.

##### mysql.thor
Mysql specific tasks

##### s3.thor
Amazon S3 tasks - upload and retrieve.

##### utils.rb
Does exactly what is says on the tin…  Utility / Helper methods. 

## Test procedure with a clean install ubuntu

Check the version of the installed OS(either in a local window or ssh into the box):
  
    cat /etc/issue; cat /etc/lsb-release
    
Change into the scripts/ubuntu_bootstrap directory

    cd scripts/ubuntu_bootstrap

Run the ssh setup script if you don't want be typing your password all the time
(NOTE: You must have a .ssh dir created on your working machine)

    ./sshSetup hgilmour 172.16.193.129

Run the launch script:

    ./launch hgilmour 172.16.193.129

Change to the chef directory

    cd ../../chef

Run the launch script (You'll have to enter your password for the first sudo command)

    ./launch hgilmour 172.16.193.129

Change to the thor directory

    cd ../thor

Run the launch script (copies the required files over to the target machine)

    ./launch hgilmour 172.16.193.129
