file_store_path "/etc/chef"
file_cache_path "/etc/chef"
cookbook_path ["/etc/chef/cookbooks", "/etc/chef/site-cookbooks"]
log_level :debug
log_location "/etc/chef/log"
ssl_verify_mode :verify_none
Chef::Log::Formatter.show_time = true
