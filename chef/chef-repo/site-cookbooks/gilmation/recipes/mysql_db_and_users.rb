#
# Cookbook Name:: gilmation
# Recipe:: mysql_db_and_users
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
# mysql creation of the db and users

Gem.clear_paths # needed for Chef to find the gem...
require 'mysql' # requires the mysql gem

execute "create #{node[:db][:name]} database" do
  command "/usr/bin/mysqladmin -u root -p#{node[:mysql][:server_root_password]} create #{node[:db][:name]}"
  not_if do
    m = Mysql.new(@node[:mysql][:bind_address], "root", @node[:mysql][:server_root_password])
    m.list_dbs.include?(@node[:db][:name])
  end
end

ruby "create #{node[:db][:user]} user" do
  m = Mysql.new(@node[:mysql][:bind_address], "root", @node[:mysql][:server_root_password])
  m.query("GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, DROP ON #{@node[:db][:name]}.* to '#{@node[:db][:user]}'@'#{@node[:mysql][:bind_address]}' IDENTIFIED BY '#{@node[:db][:password]}'")
  not_if do
    test_m = Mysql.new(@node[:mysql][:bind_address], "root", @node[:mysql][:server_root_password])
    result = test_m.query("Select * from mysql.User where User='#{@node[:db][:user]}'")
    result && result.num_rows > 0
  end
end
