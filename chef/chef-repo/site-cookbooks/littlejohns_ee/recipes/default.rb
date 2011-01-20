#
# Cookbook Name:: littlejohns_ee
# Recipe:: default
#
# Copyright 2009, Gilmation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "apache2"
include_recipe "apache2::mod_php5"
include_recipe "apache2::mod_rewrite"
include_recipe "php::php5"
include_recipe "mysql::server"

# Ensure that lvm is up to date
include_recipe "lvm"

# Make sure that we create the users that we need
include_recipe "user"

# Include Git so that we can get the code
include_recipe "git"

# Now do the Littlejohns specific stuff

# Create the deployment root directory
# Default action is create
directories = [
  "#{node[:littlejohns][:webroot]}",
  "#{node[:littlejohns][:webroot]}/shared",
  "#{node[:littlejohns][:webroot]}/shared/assets",
  "#{node[:littlejohns][:webroot]}/shared/assets/images",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/avatars",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/avatars/uploads",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/captchas",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/member_photos",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/pm_attachments",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/signature_attachments",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads/home",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads/tenants",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads/landlords",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads/accreditations",
  "#{node[:littlejohns][:webroot]}/shared/assets/images/uploads/properties",
  "#{node[:littlejohns][:webroot]}/shared/config",
  "#{node[:littlejohns][:webroot]}/releases"
]

directories.each do |dir|
  directory dir do
    owner node[:ee][:user]
    group node[:littlejohns][:apache_group]
    mode node[:ee][:mode]
    recursive true
  end
end

# Add littlejohns as a virtual host in Apache
template "/etc/apache2/sites-available/littlejohns-site" do
  source "littlejohns-site.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "apache2")
end

apache_site "littlejohns-site"

# Create config.php for Expression Engine only if one doesn't exist
template "#{node[:littlejohns][:webroot]}/shared/config/config.php" do
  source "config.php.erb"
  owner node[:ee][:user]
  group node[:littlejohns][:apache_group]
  mode node[:ee][:mode]
  not_if do File.exists?("#{node[:littlejohns][:webroot]}/shared/config/config.php") end
end

# Create database.php for Expression Engine only if one doesn't exist
template "#{node[:littlejohns][:webroot]}/shared/config/database.php" do
  source "database.php.erb"
  owner node[:ee][:user]
  group node[:littlejohns][:apache_group]
  mode node[:ee][:mode]
  not_if do File.exists?("#{node[:littlejohns][:webroot]}/shared/config/database.php") end
end

# AWS configuration
include_recipe "gilmation::aws"

# EE configuration
node[:users].each do | user |

  directory "#{user[:home]}/.ee" do
    owner user[:user]
    group user[:group]
    recursive true
    mode 0700
  end

  template "#{user[:home]}/.ee/littlejohns.yml" do
    source "littlejohns.yml.erb"
    owner user[:user]
    group user[:group]
    mode 0600
  end
end

# Create database and users
include_recipe "gilmation::mysql_db_and_users"

# Install Gems
[ "thor", "right_aws" ].each do | gem |
  gem_package gem
end
