#
# Author::  Joshua Timberman (<joshua@opscode.com>)
# Cookbook Name:: php
# Recipe:: php5
#
# Copyright 2009, Opscode, Inc.
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
include_recipe "php::module_mysql"
#include_recipe "php::module_ldap"
#include_recipe "php::module_memcache"
#include_recipe "php::module_gd"
#include_recipe "php::module_pgsql"
#include_recipe "php::pear"

remote_file value_for_platform([ "centos", "redhat", "suse" ] => {"default" => "/etc/php.ini"}, "default" => "/etc/php5/apache2/php.ini") do
  source "apache2-php5.ini"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources("service[apache2]"), :delayed
end

directory "/var/log/php" do
  owner node[:gilmation][:apache_user]
  group node[:gilmation][:apache_group]
  mode 0700
  recursive true
end

directory "/var/www/sessions" do
  owner node[:gilmation][:apache_user]
  group node[:gilmation][:apache_group]
  mode 0700
  recursive true
end

directory "/var/www/tmp" do
  owner node[:gilmation][:apache_user]
  group node[:gilmation][:apache_group]
  mode 0700
  recursive true
end

%w{ php5 }.each do |pkg|
  package pkg do
    action :upgrade
  end
end
