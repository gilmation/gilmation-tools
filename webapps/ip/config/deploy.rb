#$:.unshift(File.expand_path('./lib', ENV['rvm_path']))
#require 'rvm/capistrano'
#require 'bundler/capistrano'

set :application, "ip.gilmation.com"

# the ip or name of the domain
set :domain, '79.125.118.188'

# the path to your new deployment directory on the server
# by default, the name of the application (e.g. "/var/www/sites/example.com")
set :deploy_to, "/var/www/sites/#{application}"

set :repository, "git@github.com:gilmation/littlejohns_cc.git"

# the branch you want to clone (default is master)
set :branch, "master"

# the name of the deployment user-account on the server
set :user, "deploy"

set :scm, :git
set :ssh_options, { :forward_agent => true }
set :deploy_via, :remote_cache
set :copy_strategy, :checkout
set :keep_releases, 3
set :use_sudo, false
set :copy_compression, :bz2

# Roles
role :app, domain #"#{application}"
role :web, domain #"#{application}"
role :db,  domain, :primary => true #"#{application}", :primary => true

after "deploy", "deploy:remove_non_prod_dirs"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do

  desc "Remove non production directories from the deployed application"
  task :remove_non_prod_dirs, :roles => :app do
    run "rm -rf #{current_release}/config && rm #{current_release}/Capfile && rm #{current_release}/ip_client.rb"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
     run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
