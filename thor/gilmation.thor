# 
# Utility Thor methods for use by 
# Gilmation
# 
class Gilmation < Thor

  desc("store_mysql_dump_s3", "Store a dump of the db described by the config under the file_name and bucket_name given")
  method_option(:keep, :type => :boolean, :default => true)
  def store_mysql_dump_s3(file_name, bucket_name, config)
    puts("File name [#{file_name}]")
    puts("Bucket name [#{bucket_name}]")
    dump_file = invoke("mysql:create_mysql_dump", [ file_name, config ])
    puts("Dump File is [#{dump_file}]")
    invoke("s3:upload_file", [ file_name, bucket_name, dump_file ]) 
  end

  desc("restore_mysql_dump_s3", "Restore a dump of a db retrieved from the given bucket in s3")
  method_option(:keep, :type => :boolean, :default => true)
  def restore_mysql_dump_s3(bucket_name, config)
    puts("Bucket name [#{bucket_name}]")
    dump_file = invoke("s3:get_file", [ bucket_name ])
    invoke("mysql:load_mysql_dump", [ dump_file, config ])
  end
end
