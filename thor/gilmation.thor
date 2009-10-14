# 
# Utility Thor methods for use by 
# Gilmation
# 
class Gilmation < Thor

  desc("store_mysql_dump_s3", "Store a dump of the db described by the config under the file_name and bucket_name given")
  def store_mysql_dump_s3(file_name, bucket_name, config)
    puts "File name [#{file_name}]"
    puts "Bucket name [#{bucket_name}]"
    dump_file = invoke("mysql:create_mysql_dump", [ file_name, config ])
    puts "Dump File is [#{dump_file}]"
    invoke("s3:upload_file", [ file_name, bucket_name, dump_file ]) 
  end
end
