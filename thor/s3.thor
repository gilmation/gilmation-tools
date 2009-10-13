require 'yaml'
require 'right_aws'
require 'fileutils'
include FileUtils::Verbose

#
# Utility methods for accessing and manipulating 
# Amazon s3
#
class s3 < Thor

  # Upload the mysql dump file to S3 for this_release.  The configuration
  # of S3 is contained in the 3rd argument.
  # @param this_release [String] the release associated with this request
  # @param file [String] the file (absolute path) for request
  # @param config [String] the filename of the S3 configuration information
  desc("upload_file", "")
  def upload_file(key, bucket_name, file, config)

    # load the config

    aws_access_key_id = config['access_key_id']
    aws_secret_access_key = config['secret_access_key']
    #bucket_name = config['db_backups_bucket_name']

    s3 = RightAws::S3.new(aws_access_key_id, aws_secret_access_key)

    # create the bucket - if it doesn't already exist
    remote_bucket = RightAws::S3::Bucket.create(s3, "#{bucket_name}", true)

    # add this file
    remote_bucket.put(key, IO.read(file))
  
    # have a look at the keys that are already present
    remote_bucket.keys.each { |remote_key| puts "bucket [#{bucket_name}] contains key [#{remote_key}]" }
    rm_r(file)
  end

  desc("", "")
  def manage_uploads(config)

    # load the config

  end
end
