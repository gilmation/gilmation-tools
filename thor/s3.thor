require 'yaml'
require 'fog'
require 'fileutils'

#
# Utility methods for accessing and manipulating 
# Amazon s3
#
class S3 < Thor
  include FileUtils::Verbose

  S3_DOWNLOAD_DIR = '/tmp/s3_downloads'

  # Upload the file to S3 for this_release.  The configuration
  # of S3 is contained in the users home directory (see the private connect 
  # method for details)
  # @param key [String] the release associated with this request
  # @param bucket_name [String] the bucket where the information is to be stored
  # @param file [String] the file (absolute path) for request
  desc("upload_file", "Store the file with the given key and bucket in this users S3 repo")
  method_option(:keep, :type => :boolean, :default => false)
  def upload_file(key, bucket_name, file)

    # create the bucket - if it doesn't already exist
    directory = get_directory("#{bucket_name}")

    # add this file
    directory.files.create(
      :key => key,
      :body => File.read(file),
    )

    # have a look at the keys that are already present
    directory.files.each { |remote_key| puts "bucket [#{bucket_name}] contains key [#{remote_key}]" }

    # delete the uploaded file
    rm_r(file) unless options.keep?
  end

  # Get the file from S3 with the given key.  If the key is nil then 
  # ask the user which key they would like to use.  The configuration
  # of S3 is contained in the users home directory (see the private connect 
  # method for details)
  # If there are no keys then exit.
  # @param bucket_name [String] the bucket where the information is stored
  # @param key [String] the release associated with this request
  desc("get_file", "Get the file with the (key) and bucket from this users S3 repo")
  def get_file(bucket_name, key=nil)

    # allow the user to choose a different bucket from the one that's in the config
    bucket_name = select_from_available_buckets(bucket_name) 

    # create the bucket - if it doesn't already exist
    remote_bucket = get_directory("#{bucket_name}")

    # blank line
    puts

    if(remote_bucket.files.empty?)
      puts("There are no keys in the bucket [#{bucket_name}], exiting…")
      exit(true)
    end

    keys_table = []
    remote_bucket.files.each_with_index do | key, index |
      keys_table << [ "(#{index + 1})", key ]
    end
    print_table(keys_table)

    number = ask("Select the number of the key you would like to retrieve: ", Thor::Shell::Color::BLUE)
    throw "Invalid number #{number} chosen, cannot continue" unless number =~ /^[0-9]*$/
    throw "Number #{number} is out of range, cannot continue" if number.to_i < 1 || number.to_i > keys_table.length 
    number = number.to_i - 1

    # get the file
    puts("Getting object for key #{remote_bucket.files[number]}")
    file_download = remote_bucket.files.get(remote_bucket.files[number])

    mkdir_p(S3_DOWNLOAD_DIR)
    output_file = File.join(S3_DOWNLOAD_DIR, remote_bucket.files[number].to_s)
    File.open(output_file, "w") do | file |
      file.print(file_download)
    end
    puts("Retrieved file stored in [#{output_file}]")
    
    return output_file
  end

  # List the contents of the given bucket
  # @param bucket_name [String] the bucket where the information is to be stored
  desc("list_contents_bucket", "List the contents of this bucket in the current users S3 repo")
  def list_contents_bucket(bucket_name)

    # create the bucket - if it doesn't already exist
    remote_bucket = get_directory("#{bucket_name}")

    # have a look at the keys that are already present
    remote_bucket.files.each { |remote_key| puts "bucket [#{bucket_name}] contains key [#{remote_key}]" }
  end
  
  # List the available buckets
  desc("list_available_buckets", "List the available buckets in the current users S3 repo")
  def list_available_buckets

    # get the available buckets
    # then list them
    connect.directories.each { |bucket| puts "Bucket [#{bucket.key}]" }
  end

  # Select a bucket from those available to this user
  desc("select_from_available_buckets", "Choose a bucket from the list of available buckets")
  def select_from_available_buckets(default_bucket_name)

      keys_table = []
      connect.files.each_with_index do |bucket, index| 
        keys_table << [ "(#{index + 1})", bucket.key ]
      end
      print_table(keys_table)

      number = ask("Select a number or hit enter [#{default_bucket_name}]", Thor::Shell::Color::BLUE)
      if(number.nil? || number.empty?) 
        return default_bucket_name
      end
      throw "Invalid number #{number} chosen, cannot continue" unless number =~ /^[0-9]*$/
      throw "Number #{number} is out of range, cannot continue" if number.to_i < 1 || number.to_i > keys_table.length 
      number = number.to_i - 1

      # get the name of the bucket
      bucket_name = keys_table[number][1]
      puts("Got bucket name [#{bucket_name}]")
      return bucket_name
  end

  # Manage the contents of the given bucket
  # Save the $number of key/values in this bucket, ordered by date, delete the rest
  # @param bucket_name [String] the bucket where the information is to be stored
  # @param number [int] the number of elements (key/values) to save
  desc("manage_uploads", "Save the $number of key/values in this bucket, ordered by date, delete the rest")
  def manage_uploads(bucket_name, number=5)

    if number == 0
      puts("It is not possible to delete all the backups you need to do it manually")
      number = 1
    end

    # create the bucket - if it doesn't already exist
    remote_bucket = get_directory("#{bucket_name}")

    # Get keys ordered by date
    # save only $number key/values
    key_list = remote_bucket.files

    if(key_list.empty? || key_list.size < number)
      puts("The number of keys is [#{key_list.size}], nothing to delete")
    end 

    puts("There are [#{key_list.size}] keys, saving the last [#{number}]")
    key_list.slice!(key_list.size - number, key_list.size)

    key_list.each do | key |
      puts("Deleting key [#{key}]")
      remote_bucket.files.delete(key)
    end
  end

  private
  # Connect to S3.  The configuration
  # of S3 is contained in the users ~/.aws/aws.yml file.
  def connect
    # load the config
    config = YAML.load_file(File.join(ENV['HOME'], '.aws', 'aws.yml'))

    # Sanity check the config
    throw "Cannot connect with an empty configuration Hash" if config.empty?

    return Fog::Storage.new(
      :provider => 'AWS',
      :aws_access_key_id => config['access_key_id'],
      :aws_secret_access_key => config['secret_access_key']
    )
  end

  # Get the directory refered to by the name
  # If it doesn't exist then create it.
  def get_directory(name)
    directory = connect.directories.get("#{name}")
    unless directory
      directory = connect.directories.create(
        :key => "#{name}"
      )
    end
    directory
  end
end
