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

    # add the forum_attachments directory to the shared_image_dirs list (comment this if you are not using the forum module)
    @shared_image_dirs << "images/forum_attachments"

    # Get the config file
    ee_config_file = if(options[:config_file] && File.exists?(options[:config_file]))
                        options[:config_file] 
                     else
                        File.join(ENV['HOME'], '.ee', options[:config_file])
                     end

    puts "Using config file [#{ee_config_file}]"

    @ee_config = YAML.load_file(ee_config_file)
    @deploy_root = @ee_config['deploy']['root']
    @ee_system = @ee_config['deploy']['system_name']
    @ee_dir = File.join(ENV['EE_HOME'], @ee_config['deploy']['ee_dir'])

    ## assets dir
    @assets_dir = "#{@deploy_root}/#{@shared_dir}/assets"

    return @ee_config
  end

  desc "deploy_local", "Development Expression Engine install to the local web deploy root (as per the configuration)"
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def deploy_local
    invoke :ee_config
    invoke :check_create_directories
    invoke :copy_files
    invoke :create_links
    invoke :check_ee_config
  end

  desc "check_create_directories", "If they don't exist create them"
  def check_create_directories

    # if shared sub-directories do not exist create them and copy in the default index.html file
    @shared_image_dirs.each do | dir |
      mkdir_p("#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}")
      # make sure that the permissions are ok
      chmod_R(0777, "#{@assets_dir}/#{dir}")
      # add an index.html file for anyone that accesses this directory directly but don't set the permissions to wide open
      cp("#{@ee_dir}/images/index.html", "#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}/index.html")
    end

    # if shared config directory does not exist then create it
    mkdir_p("#{@deploy_root}/#{@shared_dir}/config") unless File.exists?("#{@deploy_root}/#{@shared_dir}/config")

    # create this_release directory, creating the releases directory if it does not already exist
    mkdir_p("#{@deploy_root}/#{@releases_dir}/#{@this_release}")
  end

  desc("copy_files", 
    "Copy the contents of the directory refered to by the ee_dir variable to the this_release directory and setup the permissions")
  def copy_files
    cp_r(FileList.new("#{@ee_dir}/*", "#{@ee_dir}/.htaccess"), "#{@deploy_root}/#{@releases_dir}/#{@this_release}")

    # setup the correct permissions
    chmod(0666, "#{@deploy_root}/#{@releases_dir}/#{@this_release}/path.php")
    chmod(0777, "#{@deploy_root}/#{@releases_dir}/#{@this_release}/#{@ee_system}/cache/")
    chmod(0666, "#{@deploy_root}/#{@releases_dir}/#{@this_release}/#{@ee_system}/config_bak.php")
    #chmod(0755, "#{@deploy_root}/#{@releases_dir}/#{@this_release}/#{@ee_system}/translations")
  end

  desc "check_ee_config", "Make sure that the config files exist and are up to date"
  def check_ee_config

  end

  desc "deploy_local_config", "This is a generated configuration and should not be stored in git"
  def deploy_local_config

  end

  desc("create_links",
  "Create the links needed to set up the current deployment and make the shared files available to it")
  def create_links
    # link to the deployed code
    File.exists?("#{@deploy_root}/#{@current_release}") && rm("#{@deploy_root}/#{@current_release}")
    ln_s("#{@deploy_root}/#{@releases_dir}/#{@this_release}", "#{@deploy_root}/#{@current_release}")

    # the config file
    #ln_s("#{@deploy_root}/#{@shared_dir}/config/config.php", "#{@deploy_root}/#{@current_release}/#{@ee_system}/config.php")

    # standard image upload directories
    @shared_image_dirs.each do | dir |
      ln_s("#{@assets_dir}/#{dir}", "#{@deploy_root}/#{@current_release}/#{dir}")
    end
  end

  desc("delete_shared_files", "Delete the files that should not appear in the source code repository")
  def delete_shared_files
    @shared_image_dirs.each do | dir |
      rm_r("#{@ee_dir}/#{dir}")
    end
  end

  desc("clear_cache", "Clear the caches if they exist")
  def clear_cache
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/db_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/db_cache/*")
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/page_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/page_cache/*")
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/magpie_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/magpie_cache/*")
  end

  desc("manage_deployments", "Given a number, defaults to 5, save the most recent $number of deployments and delete the rest")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def manage_deployments(number = 5)

    case(number)
    when String then number = number.to_i
    end

    if(number <= 0)
      throw('Cannot process a zero or negative number of deployments')
    end

    #get the config info
    invoke :ee_config

    #get the list of ordered deployment dirs
    deployments = Dir.glob("#{@deploy_root}/#{@releases_dir}/*").sort{|a,b| File.mtime(b) <=> File.mtime(a)}

    if(!deployments)
      puts("There are no deployments in [#{@deploy_root}/#{@releases_dir}/*]")
      return 
    end
    
    if(deployments.length <= number)
      puts("No deployments to delete")
      return
    end

    # get rid of the number of deployments that we don't want to delete
    number = number-1 unless number == 1
    deployments.slice!(0, number)
    puts("There are [#{deployments.length}] deployments to be deleted")

    #make sure that we don't delete the one current is pointing to
    if(deployments.delete(File.readlink("#{@deploy_root}/#{@current_release}")))
      puts("Oops, the current link is pointing to a file that's in the list of deployments to delete")
      puts("Removed this deployment from the liquidation list !")
    end

    if(deployments.length != 0)
      puts("Deleting [#{deployments.length}] deployments")
      FileUtils.rm_rf(deployments, :secure => true)
    else 
      puts("Not deleting any deployments")
    end
  end

  desc("store_mysql_dump_s3", "Store a mysqldump file in s3 for this Database and user")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def store_mysql_dump_s3
    invoke(:ee_config)
    invoke("gilmation:store_mysql_dump_s3", [ @this_release, @ee_config ]) 
  end

  desc("restore_mysql_dump_s3", "Restore a mysqldump file from s3 for this Database and user")
  method_option(:config_file, :default => "ee.yml", :type => :string, :aliases => "-f")
  def restore_mysql_dump_s3
    invoke(:ee_config)
    invoke("gilmation:restore_mysql_dump_s3", [ @ee_config ]) 
  end
end
