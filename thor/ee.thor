require 'yaml'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'utils.rb')

#
# Methods for the configuration and deployment of an
# Expression Engine instance
#
class Ee < Thor
  include FileUtils::Verbose
  include Gilm::Utils

  map "-c" => :list_config

  desc "list_config", "Output the configuration that we have loaded from file"
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def list_config

    puts "Config file values are"
    ee_config.each do | key, value |
      show_string_hash(key, value)
    end
    puts "######"
    puts "Derived config values are"
    puts "assets_dir [#{@assets_dir}]"
    puts "ee_dir [#{@ee_dir}]"
    puts "this_release [#{@this_release}]"
    
    puts "######"
    puts "Shared image dirs are"
    @shared_image_dirs.each do | dir |
      puts "[#{dir}]"
    end
  end

  desc "ee_config",
  "Get the configuration, filename or path (concatenates the environmental variable EE_HOME unless filename can be found)"
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def ee_config

    # return the config if it already exists
    return @ee_config if @ee_config

    # else create the config if it doesn't already exist

    #
    # Variables
    #
    @shared_dir = :shared
    @releases_dir = :releases
    @current_release = :current
    @this_release = Time.now.strftime("%Y%m%d_%H%M")

    # shared image dirs
    @shared_image_dirs = [ "images/avatars/uploads", "images/captchas",
      "images/member_photos", "images/pm_attachments",
    "images/signature_attachments", "images/uploads" ]

    # Get the config file
    puts "Using home [#{ENV['HOME']}], config_file [#{options[:config_file]}]"
    ee_config_file = if(options[:config_file] && File.exists?(options[:config_file]))
                        options[:config_file] 
                     else
                        File.join(ENV['HOME'], '.ee', options[:config_file])
                     end

    puts "Using config file [#{ee_config_file}]"

    @ee_config = YAML.load_file(ee_config_file)
    @deploy_root = @ee_config['deploy']['root']
    @ee_system = @ee_config['deploy']['ee_system']
    @ee_dir = @ee_config['deploy']['ee_dir']
    @cache_dir = @ee_config['deploy']['cache_dir']
    @config_file = @ee_config['deploy']['config_file']
    @database_file = @ee_config['deploy']['database_file']

    # add the forum_attachments directory to the shared_image_dirs list (comment this if you are not using the forum module)
    if(@ee_config['deploy']['extra_image_dirs']) 
      @shared_image_dirs << @ee_config['deploy']['extra_image_dirs']
    end

    ## assets dir
    @assets_dir = "#{@deploy_root}/#{@shared_dir}/assets"
    @shared_config_dir = "#{@deploy_root}/#{@shared_dir}/config"

    return @ee_config
  end

#
# No physical local deployment - don't copy the files into the web deployment directory
# Create a link to them instead
#

  desc "deploy_local", "Link the development Expression Engine install to the local web deploy root (as per the configuration)"
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def deploy_local
    ee_config
    check_create_shared_directories
    create_deploy_link
    create_shared_links
  end

  desc("create_deploy_link", "Deploy the code by using a link to the development project dir")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def create_deploy_link
    #get the config info
    ee_config

    # link the web dir
    File.exists?("#{@deploy_root}/#{@current_release}") && rm("#{@deploy_root}/#{@current_release}")
    ln_s("#{@ee_dir}", "#{@deploy_root}/#{@current_release}") 
  end

  desc "check_create_shared_directories", "If the shared directories don't exist then create them"
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def check_create_shared_directories
    #get the config info
    ee_config

    # if shared sub-directories do not exist create them and copy in the default index.html file
    @shared_image_dirs.each do | dir |
      mkdir_p("#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}")
      # make sure that the permissions are ok
      chmod_R(0777, "#{@assets_dir}/#{dir}")
      # add an index.html file for anyone that accesses this directory directly but don't set the permissions to wide open
      cp("#{@ee_dir}/images/index.html", "#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}/index.html")
    end
  end

  desc("create_shared_links", "Create the links that we need to use the shared assets dirs")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def create_shared_links
    # get the config info
    ee_config

    # standard image upload directories
    @shared_image_dirs.each do | dir |
      ln_s("#{@assets_dir}/#{dir}", "#{@ee_dir}/#{dir}") unless File.exists?("#{@ee_dir}/#{dir}")
    end
  end

#
# General methods
#

  desc("delete_shared_dirs", "Delete the dirs that should not appear in the source code repository")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def delete_shared_dirs
    # get the config info
    ee_config

    @shared_image_dirs.each do | dir |
      if(File.exists?("#{@ee_dir}/#{dir}") && File.directory?("#{@ee_dir}/#{dir}"))
         rm_r("#{@ee_dir}/#{dir}")
      end
    end
  end

  desc("create_gitignore", "Does exactly what it says on the tin")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def create_gitignore
    # get the config info
    ee_config
    File.open("#{@ee_dir}/.gitignore", 'a+') do |f|
      @shared_image_dirs.each { |dir| f.puts("#{dir}") }
      f.puts("#{@ee_system}/#{@config_file}")
      @database_file && f.puts("#{@ee_system}/#{@database_file}")
      f.puts("#{@ee_system}/#{@cache_dir}/*cache")
    end
  end

  desc("create_shared_dirs", "Create the dirs that should not appear in the source code repository")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def create_shared_dirs
    # get the config info
    ee_config

    @shared_image_dirs.each do | dir |
      mkdir_p("#{@ee_dir}/#{dir}") unless File.exists?("#{@ee_dir}/#{dir}")
      chmod(0777, "#{@ee_dir}/#{dir}")
    end
  end

  desc("move_link_config", "Get the config files, move them to the shared dirs and link them in")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def move_link_config
    # get the config info
    ee_config

    mkdir_p("#{@shared_config_dir}") unless File.exists?("#{@shared_config_dir}")
    file_list = [ @config_file, @database_file ]
    file_list.each do | file |
      name = "#{@ee_dir}/#{@ee_system}/#{file}"
      short_name = File.basename(file)
      puts("Looking for file [#{name}]") 
      if(File.exists?(name))
        mv(name, @shared_config_dir)
        ln_s("#{@shared_config_dir}/#{short_name}", name)
        chmod(0644, "#{@shared_config_dir}/#{file}")
      end
    end
  end

  desc("clear_cache", "Clear the caches if they exist")
  def clear_cache
    # get the config info
    ee_config

    rm_r("#{ee_dir}/#{@ee_system}/#{cache_dir}/*cache")
  end

  desc("store_mysql_dump_s3", "Store a mysqldump file in s3 for this Database and user")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def store_mysql_dump_s3
    ee_config
    invoke("gilmation:store_mysql_dump_s3", [ @this_release, @ee_config ])
  end

  desc("restore_mysql_dump_s3", "Restore a mysqldump file from s3 for this Database and user")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def restore_mysql_dump_s3
    ee_config
    invoke("gilmation:restore_mysql_dump_s3", [ @ee_config ]) 
  end

  desc("store_uploaded_images_s3", "Store the uploaded images in s3")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def store_uploaded_images_s3
    ee_config
    invoke("gilmation:store_uploaded_images_s3", [ @this_release, @ee_config, @assets_dir ]) 
  end

  desc("restore_uploaded_images_s3", "Restore the uploaded images from s3")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def restore_uploaded_images_s3
    ee_config
    invoke("gilmation:restore_uploaded_images_s3", [ @ee_config, @assets_dir ]) 
    #invoke(:create_links)
  end

  desc("update_mh_files", "Update the information for the mh_file fields with a format of none")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def update_mh_files
    ee_config
    invoke("mysql:update_mh_file_format", [ @ee_config ]) 
  end
end
