#
# Cookbook Name:: user
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
node[:users].each do | user |
  group user[:group] do
    gid user[:gid]
    action :create
  end

  #directory "#{user[:home]}" do
    #owner user[:user]
    #group user[:group]
    #mode 0755
  #end

  user user[:user] do
    comment user[:comment]
    home user[:home]
    shell "/bin/bash"
    uid user[:uid]
    gid user[:gid]
    action :create
  end

  directory "#{user[:home]}/.ssh" do
    owner user[:user]
    group user[:group]
    recursive true
    mode 0700
  end

  %w{ id_rsa id_rsa.pub authorized_keys }.each do |ssh_file|
    remote_file "#{user[:home]}/.ssh/#{ssh_file}" do
      source ssh_file
      owner user[:user]
      group user[:group]
      if ssh_file.include?("pub")
        mode 0644
      else 
        mode 0600
      end
      if user[:cookbook]
        cookbook user[:cookbook]
      end
    end
  end
end
