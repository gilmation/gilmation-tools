require 'yaml'
require 'right_aws'
require 'fileutils'
include FileUtils::Verbose

#
# Methods for the configuration and deployment of an
# Expression Engine instance
#
class Ee < Thor
  map "-c" => :list_config

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

  desc "Print the configuration that is being / going to be used"
  method_options(:config_file, :default => "config.yml", :type => :string, :aliases => "-conf")
  def list_config
    ee_config.each do | key, value |
      puts "[#{key}] is [#{value}]"
    end
    puts "######"
    puts "Shared image dirs are"
    shared_image_dirs.each do | dir |
      puts "[#{dir}]"
    end
  end

  desc "Load the configuration file that we need to be able to do anything",
  "Option: -conf=filename or path to file (this option will concatenate environmental variable EE_HOME",
  " unless a file can be found for the input)"
  method_options(:config_file, :default => "config.yml", :type => :string, :aliases => "-conf")
  def ee_config

    # config
    return @ee_config if @@ee_config

    # else
    ee_config_file = File.exists?(options[:config_file]) && options[:config_file] ||
    File.join(ENV['EE_HOME'], options[:config_file])

    config = YAML.load_file(ee_config_file)
    #config = YAML.load_file("./config/config.yml")
    @@ee_config = config['local']
    @deploy_root = config_node['deploy']['root']
    @ee_system = config_node['deploy']['system_name']
    @ee_dir = ENV[:EE_HOME] || config_node['deploy']['ee_dir']

    # assets dir
    @assets_dir = "#{deploy_root}/#{shared_dir}/assets"

    return @ee_config
  end

  desc "Deploy the development Expression Engine install to the local web deploy root (as per the configuration)"
  method_options(:config_file, :default => "config.yml", :type => :string, :aliases => "-conf")
  def deploy_local
    invoke :create_links
    invoke :check_ee_config
  end

  desc "Check required local directories and if they don't exist create them"
  def check_create_directories

    # if shared sub-directories do not exist create them and copy in the default index.html file
    @shared_image_dirs.each do | dir |
      mkdir_p("#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}")
      # make sure that the permissions are ok
      chmod_R(0777, "#{@assets_dir}/#{dir}")
      # add an index.html file for anyone that accesses this directory directly but don't set the permissions to wide open
      cp("./#{@ee_dir}/images/index.html", "#{@assets_dir}/#{dir}") unless File.exists?("#{@assets_dir}/#{dir}/index.html")
    end

    # if shared config directory does not exist then create it
    mkdir_p("#{@deploy_root}/#{@shared_dir}/config") unless File.exists?("#{@deploy_root}/#{@shared_dir}/config")

    # create this_release directory, creating the releases directory if it does not already exist
    mkdir_p("#{@deploy_root}/#{@releases_dir}/#{@this_release}")
  end

  desc "Copy the contents of the directory refered to by the ee_dir variable to the this_release directory and setup the permissions"
  def copy_files
    cp_r(FileList.new("./#{@ee_dir}/*", "./#{@ee_dir}/.htaccess"), "#{@deploy_root}/#{@releases_dir}/#{@this_release}")

    # setup the correct permissions
    chmod(0666, "#{deploy_root}/#{releases_dir}/#{this_release}/path.php")
    chmod(0777, "#{deploy_root}/#{releases_dir}/#{this_release}/#{ee_system}/cache/")
    chmod(0666, "#{deploy_root}/#{releases_dir}/#{this_release}/#{ee_system}/config_bak.php")
    chmod(0666, "#{deploy_root}/#{releases_dir}/#{this_release}/#{ee_system}/translations")
  end

  desc ""
  def check_ee_config

  end

  desc "Deploy the local configuration - not stored in git"
  def deploy_local_config

  end

  desc "Create the links needed to set up the current deployment and make the shared files available to it"
  def create_links
    # link to the deployed code
    File.exists?("#{@deploy_root}/#{@current_release}") && rm("#{@deploy_root}/#{@current_release}")
    ln_s("#{@deploy_root}/#{@releases_dir}/#{@this_release}", "#{@deploy_root}/#{@current_release}")

    # the config file
    #ln_s("#{@deploy_root}/#{@shared_dir}/config/config.php", "#{@deploy_root}/#{@current_release}/#{@ee_system}/config.php")

    # standard image upload directories
    shared_image_dirs.each do | dir |
      ln_s("#{@assets_dir}/#{dir}", "#{@deploy_root}/#{@current_release}/#{dir}")
    end
  end

  desc "Delete the shared files that should not appear in the source code repository"
  def delete_shared_files
    shared_image_dirs.each do | dir |
      rm_r("#{@ee_dir}/#{dir}")
    end
  end

  desc "Clear the ExpressionEngine caches if they exist"
  def clear_cache
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/db_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/db_cache/*")
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/page_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/page_cache/*")
    File.exists?("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/magpie_cache") && rm_r("#{@deploy_root}/#{@current_release}/#{@ee_system}/cache/magpie_cache/*")
  end
end
