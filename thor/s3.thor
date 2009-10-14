require 'yaml'
require 'right_aws'
require 'fileutils'

#
# Utility methods for accessing and manipulating 
# Amazon s3
#
class S3 < Thor
  include FileUtils::Verbose

  # Upload the file to S3 for this_release.  The configuration
  # of S3 is contained in the users home directory (see the private connect 
  # method for details)
  # @param key [String] the release associated with this request
  # @param bucket_name [String] the bucket where the information is to be stored
  # @param file [String] the file (absolute path) for request
  desc("upload_file", "Store the file with the given key and bucket in this users S3 repo")
  def upload_file(key, bucket_name, file)

    # create the bucket - if it doesn't already exist
    remote_bucket = RightAws::S3::Bucket.create(connect, "#{bucket_name}", true)

    # add this file
    remote_bucket.put(key, IO.read(file))
  
    # have a look at the keys that are already present
    remote_bucket.keys.each { |remote_key| puts "bucket [#{bucket_name}] contains key [#{remote_key}]" }
    rm_r(file)
  end

  # Get the file from S3 with the given key.  The configuration
  # of S3 is contained in the users home directory (see the private connect 
  # method for details)
  # @param key [String] the release associated with this request
  # @param bucket_name [String] the bucket where the information is stored
  desc("get_file", "Get the file with the given key and bucket from this users S3 repo")
  def get_file(key, bucket_name)

    # create the bucket - if it doesn't already exist
    remote_bucket = RightAws::S3::Bucket.create(connect, "#{bucket_name}", true)

    # get this file
    return remote_bucket.get(key)
  end

  # List the contents of the given bucket
  # @param bucket_name [String] the bucket where the information is to be stored
  desc("list_contents_bucket", "List the contents of this bucket in the current users S3 repo")
  def list_contents_bucket(bucket_name)

    # create the bucket - if it doesn't already exist
    remote_bucket = RightAws::S3::Bucket.create(connect, "#{bucket_name}", true)

    # have a look at the keys that are already present
    remote_bucket.keys.each { |remote_key| puts "bucket [#{bucket_name}] contains key [#{remote_key}]" }
  end

  # Manage the contents of the given bucket
  # Save the $number of key/values in this bucket, ordered by date, delete the rest
  # @param bucket_name [String] the bucket where the information is to be stored
  # @param number [int] the number of elements (key/values) to save
  desc("manage_uploads", "Save the $number of key/values in this bucket, ordered by date, delete the rest")
  def manage_uploads(bucket_name, number)

    # Connect
    s3 = connect

    # Get keys ordered by date

    # save only $number key/values

  end

  private
  # Connect to S3.  The configuration
  # of S3 is contained in the users ~/.aws/aws.yml file.
  def connect
    # load the config
    config = YAML.load_file(File.join(ENV['HOME'], '.aws', 'aws.yml'))

    # Sanity check the config
    throw "Cannot connect with an empty configuration Hash" if config.empty?

    return RightAws::S3.new(config['access_key_id'], config['secret_access_key'])
  end
end
