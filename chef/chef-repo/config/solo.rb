file_store_path "/tmp/chef-solo"
file_cache_path "/tmp/chef-solo"
cookbook_path "/tmp/chef-solo/cookbooks"
log_level :info
log_location "/tmp/chef-solo/logs"
ssl_verify_mode :verify_none
Chef::Log::Formatter.show_time = true
