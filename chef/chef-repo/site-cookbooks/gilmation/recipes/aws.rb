#
# Cookbook Name:: gilmation
# Recipe:: aws
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
# AWS configuration
node[:users].each do | user |

  directory "#{user[:home]}/.aws" do
    owner user[:user]
    group user[:group]
    recursive true
    mode 0700
  end

  template "#{user[:home]}/.aws/aws.yml" do
    source "aws.yml.erb"
    owner user[:user]
    group user[:group]
    mode 0600
  end
end

