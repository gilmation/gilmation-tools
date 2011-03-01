#
# Cookbook Name:: morpsuits
# Recipe:: default
#
# Copyright 2011, Gilmation S.L.
#
# All rights reserved - Do Not Redistribute
# Apache: mod_deflate, mod_env, mod_expires, mod_headers, mod_rewrite
# PHP: php_soap, pdo_mysql, mcrypt, gd, curl
#

include_recipe "apache2"
include_recipe "apache2::mod_php5"
include_recipe "apache2::mod_rewrite"
include_recipe "apache2::mod_deflate"
include_recipe "apache2::mod_env"
include_recipe "apache2::mod_expires"
include_recipe "apache2::mod_headers"

include_recipe "php::php5"

include_recipe "mysql::server"
