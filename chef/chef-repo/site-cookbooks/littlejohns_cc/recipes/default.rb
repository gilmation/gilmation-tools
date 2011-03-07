#
# Cookbook Name:: littlejohns_cc
# Recipe:: default
#
# Copyright 2011, Gilmation
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

# Now do the Littlejohns CC specific stuff

# Create the deployment root directory
# Default action is create
directories = [
  "#{node[:littlejohns_cc][:webroot]}",
  "#{node[:littlejohns_cc][:webroot]}/shared",
  "#{node[:littlejohns_cc][:webroot]}/shared/config",
  "#{node[:littlejohns_cc][:webroot]}/shared/assets",
  "#{node[:littlejohns_cc][:webroot]}/releases"
]

directories.each do |dir|
  directory dir do
    owner node[:cc][:user]
    group node[:littlejohns_cc][:apache_group]
    mode node[:cc][:mode]
    recursive true
  end
end

# Add littlejohns-cc as a virtual host in Apache
template "/etc/apache2/sites-available/littlejohns-cc-site" do
  source "littlejohns-cc-site.erb"
  owner "root"
  group "root"
  mode 0644
  #notifies :restart, resources(:service => "apache2")
end

apache_site "littlejohns-cc-site"

# Create database.yml for CC Rails app only if one doesn't exist
template "#{node[:littlejohns_cc][:webroot]}/shared/config/database.yml" do
  source "database.yml"
  owner node[:cc][:user]
  group node[:littlejohns_cc][:apache_group]
  mode node[:cc][:mode]
  not_if do File.exists?("#{node[:littlejohns_cc][:webroot]}/shared/config/database.yml") end
end
