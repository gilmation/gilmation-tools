require 'fileutils'
require File.join(File.dirname(__FILE__), 'utils.rb')

#
# Utility Thor methods for use by 
# Gilmation
#
class Gilmation < Thor
  include FileUtils::Verbose
  include Gilm::Utils

  IMAGE_TMP_DIR = "/tmp/image_backups"

  desc("store_mysql_dump_s3", "Store a dump of the db described by the config under the file_name and bucket_name given")
  method_option(:keep, :type => :boolean, :default => true)
  def store_mysql_dump_s3(file_name, config)
    process_config(config)
    puts("File name [#{file_name}]")
    puts("Bucket name [#{@db_backups_bucket_name}]")
    dump_file = invoke("mysql:create_mysql_dump", [ file_name, config ])
    puts("Dump File is [#{dump_file}]")
    invoke("s3:upload_file", [ file_name, @db_backups_bucket_name, dump_file ]) 
  end

  desc("restore_mysql_dump_s3", "Restore a dump of a db retrieved from the given bucket in s3")
  method_option(:keep, :type => :boolean, :default => true)
  def restore_mysql_dump_s3(config)
    process_config(config)
    puts("Bucket name in the config is [#{@db_backups_bucket_name}]")
    begin
      dump_file = invoke("s3:get_file", [ @db_backups_bucket_name ])
    rescue Interrupt
      puts
      puts("Graceful exit has been requested...request granted")
      puts
      exit!
    end
    invoke("mysql:load_mysql_dump", [ dump_file, config ])
  end

  desc("store_uploaded_images_s3", "Store all the uploaded images in s3")
  def store_uploaded_images_s3(file_name, config, assets_dir)
    process_config(config)
    puts("File name [#{file_name}]")
    bundle_file = create_bundle(file_name, assets_dir)
    puts("Bundle File is [#{bundle_file}]")
    puts("Bucket name [#{@image_backups_bucket_name}]")
    invoke("s3:upload_file", [ file_name, @image_backups_bucket_name, bundle_file ]) 
  end

  desc("restore_uploaded_images_s3", "Restore all the uploaded images from s3")
  method_option(:keep, :type => :boolean, :default => true)
  def restore_uploaded_images_s3(config, assets_dir)
    process_config(config)
    puts("Bucket name in the config is [#{@image_backups_bucket_name}]")
    dump_file = invoke("s3:get_file", [ @image_backups_bucket_name ])
    create_files(dump_file, config, assets_dir)
  end

  desc("create_bundle", "Create a gzip of a given target directory")
  def create_bundle(file_name, target_dir) 
    mkdir_p(IMAGE_TMP_DIR)

    # define the tar file
    bundle_file = "#{IMAGE_TMP_DIR}/#{file_name}_images.gz"

    # build the tar command
    cmd = "tar -zcf #{bundle_file} --exclude \"*.DS_Store\" #{target_dir}"
    puts "Command is [#{cmd}]"

    # run the tar command
    system(cmd)

    # return the location of the tar output
    return bundle_file
  end

  private 

  def process_config(config)
    # load the config
    case config
    when String then config = load_config(config)
    end

    @db_backups_bucket_name = config['db']['backups_bucket_name']
    @image_backups_bucket_name = config['image']['backups_bucket_name']
  end
end
