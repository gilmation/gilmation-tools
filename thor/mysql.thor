require 'yaml'

#
# Methods for working with MySQL
# Databases
#
class Mysql < Thor

  # Generate a mysql dump file.  The configuration of the Database is contained
  # in the second argument.
  # @param this_release [String] the release associated with this request
  # @param config [String] the location of the Database configuration information 
  desc("", "")
  def create_mysql_dump(this_release, config)

    # load the config

    # db user / password
    db_name = config['db']['name']
    db_admin_user = config['db']['admin_user']
    db_admin_password = config['db']['admin_password']
    output_dir = "/tmp/mysql_backups"

    # create the output directory
    mkdir_p(output_dir)

    # define the dump file
    dump_file = "#{output_dir}/#{this_release}_ee_dump.sql.gz"

    # build the mysqldump command
    cmd = "mysqldump --quick --single-transaction --create-options -u#{db_admin_user}"
    cmd += " -p'#{db_admin_password}'" unless db_admin_password.nil?
    cmd += " --databases #{db_name} | gzip > #{dump_file}"
    puts "Command is [#{cmd}]"

    # run the mysqldump command
    system(cmd)

    # return the location of the mysqldump output
    return dump_file
  end

  desc("", "") 
  def load_mysql_dump(dump_file, config) 

    # load the config

  end
end
