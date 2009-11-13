require 'yaml'
require 'fileutils'
require File.join(File.dirname(__FILE__), 'utils.rb')

#
# Methods for working with MySQL
# Databases
#
class Mysql < Thor
  include FileUtils::Verbose
  include Gilm::Utils

  MYSQL_BACKUP_DIR = "/tmp/mysql_backups"

  # Generate a mysql dump file.  The configuration of the Database is contained
  # in the second argument.
  # @param this_release [String] the release associated with this request
  # @param config [String] the location of the Database configuration information 
  desc("create_mysql_dump", "Generate a mysql dump file and store it in file_name for the database config given")
  def create_mysql_dump(file_name, config)

    # load the config if necessary
    case config
    when String then config = load_config(config)
    end

    # db user / password
    process_config(config)

    # create the output directory
    mkdir_p(MYSQL_BACKUP_DIR)

    # define the dump file
    dump_file = "#{MYSQL_BACKUP_DIR}/#{file_name}_ee_dump.sql.gz"

    # build the mysqldump command
    cmd = "mysqldump --quick --single-transaction --create-options -u#{@db_admin_user}"
    cmd += " -p'#{@db_admin_password}'" unless @db_admin_password.nil?
    cmd += " --databases #{@db_name} | gzip > #{dump_file}"
    puts "Command is [#{cmd}]"

    # run the mysqldump command
    system(cmd)

    # return the location of the mysqldump output
    return dump_file
  end

  desc("load_mysql_dump", "Given a mysql dump_file load it into the database described by the config parameter") 
  def load_mysql_dump(dump_file, config) 

    # load the config
    case config
    when String then config = load_config(config)
    end

    # db user / password
    process_config(config)

    # build the load command
    cmd = "gunzip -c #{dump_file} | mysql -u#{@db_admin_user}"
    cmd += " -p'#{@db_admin_password}'" unless @db_admin_password.nil?
    puts "Command is [#{cmd}]"

    # run the load command
    system(cmd)
  end

  private 
  def process_config(config)
    @db_name = config['db']['name']
    @db_admin_user = config['db']['admin_user']
    @db_admin_password = config['db']['admin_password']
  end
end
