# Gilmation Tools

This directory contains the tools used to manage Gilmation servers and the software that runs on them

#### At the present time there are three directories:
* Scripts - Bootstrap scripts and other utilities written in bash.
* Chef - System configuration scripts (mainly chef standalone). [Chef Repo](http://github.com/opscode/chef)
* Thor - Deployment, backups and storage of the backups in Amazon s3. [Thor Repo](http://github.com/wycats/thor)

## Scripts

The scripts directory contains OS specific scripts that can be used to bootstrap a new instance into a state suitable to run something a bit more "cultured" :-), in our case [Chef](http://github.com/opscode/chef).

##### launch
1. Connect to the given host (arg 2) as the given user (arg 1)
2. Copy over the setup script from this directory
3. Run the setup script

##### setup 
1. Install the minimum config necesary for a Ruby environment (Ruby and Gems)
2. Use Gems to install ohai and chef (and their dependencies)

##### sshSetup
1. Copy this users public key to the .ssh dir on the given server
2. Setting up the connection so that it won't ask for a password
3. NOTE: only for use by someone who knows what they are doing 

##### iptables
1. Setup the iptables (firewall) for a given ubuntu machine

## Chef

The chef directory contains a script launch and the chef-repo directory.  

##### launch
1. Installs the chef cookbooks 
2. Installs the $HOME/.ee/$PROJECT_NAME_site_node.json file (whcih contains the configuration necessary for this node)
3. Runs the cookbooks using chef-solo and the $PROJECT_NAME_site_node.json configuration file

NOTE: You need to run the following command first so that the launch file can connect over ssh without having to use `ssh -i`

    ssh-add $KEY_FILE_LOCATION

### The chef-repo directory contains:

##### cookbooks
These are opscode / 37 signals cookbooks that have not been modified and can be overridden by the cookbooks contained in the following directory

##### site-cookbooks
This directory contains the gilmation specific cookbooks that we run in order to configure the standard gilmation.com server.

The recipe that does most of the hard yards here is - gilmation_ee/recipes/default.rb.  This recipe calls the other site specific recipes and as well as installing the software necessary for gilmation.com it also prepares directories so that we can deploy the Expression Engine code easily with Capistrano and administer the Database with Thor.  

## Thor

Thor is a gem that allows you to write scripts in ruby (like rake) but then install them and have them available to you wherever you are on a given box.  

You can see a list of all the tasks and their descriptions (like Rake or Capistrano), by typing:

    thor -T 

Of interest to us at the moment are the 5 files that we need to install onto the standard gilmation.com server:

##### ee.thor
A list of tasks for deployment, backups and restore of Expression Engine and it's Database.

##### Using the EE Thor tasks to setup a new EE project.

1. Download the EE2 codebase and install it in your development area
2. Define a config file for your project at ~/.ee/$PROJECT_NAME.yml
3. Run 

    thor ee:deploy_local -f $PROJECT_NAME.yml

4. Create a virtual host entry (Apache)
5. Use ghost or /etc/hosts to direct the hostname to your machine
6. Set up the file permissions in the EE2 development directory as per the EE install page
7. Create the DB schema and user (The chef recipe for Mysql contains the SQL necessary)

    /usr/bin/mysqladmin -u root -p$PASSWORD create $DB_NAME
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP ON $DB_NAME.* to '$USERNAME' IDENTIFIED BY '$PASSWORD'

8. Create a .gitignore file with 

    thor ee:create_gitignore -f $PROJECT_NAME.yml

9. Run the EE2 install (http://$SERVER_NAME/$SYSTEM_DIR)
10. Run the Thor task to move the configuration files that have just been updated and create symbolic links to them: 

    thor ee:move_link_config -f $PROJECT_NAME.yml

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
