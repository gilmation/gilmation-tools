require 'fileutils'
require 'csv'
require 'yaml'
require '../common/common.rb'
require 'zendesk_api'

class ZendeskGilmationUtils
  include FileUtils::Verbose
  include Common

  def initialize
    _init_zendesk
    puts "User [#{@zendesk_user}]"
    puts "Token [#{@zendesk_token}]"

    @zendesk_client = ZendeskAPI::Client.new do |config|
      # Mandatory:

      config.url = "https://afgmedia.zendesk.com/api/v2"

      # Basic / Token Authentication
      config.username = @zendesk_user
      config.token = @zendesk_token

      # Optional:

      # Retry uses middleware to notify the user
      # when hitting the rate limit, sleep automatically,
      # then retry the request.
      config.retry = true

      # Logger prints to STDERR by default, to e.g. print to stdout:
      require 'logger'
      config.logger = Logger.new(STDOUT)

      # Changes Faraday adapter
      # config.adapter = :patron

      # Merged with the default client options hash
      # config.client_options = { :ssl => false }
    end
  end

  def find_tickets_by_email(email_file)

    results = []
    CSV.foreach(email_file, { :headers => true }) do | data |
      order_id = data['Order Number']
      name = data['Name']
      result = @zendesk_client.search(:query => "setype:ticket+requester:#{name}")
      puts "Name [#{name}], OrderID [#{order_id}] - Result [#{result.count}]"
    end


    #rm_r(filename) if File.exists?(filename)
    #CSV.open(filename, 'a') do | csv |
    #  csv << headers if headers
    #  results.sort.each do | key, value |
    #    if value.is_a?( Array )
    #      csv << value.sort.insert(0, key)
    #    else
    #      csv << [key, value]
    #    end
    #  end
    #end
  end
end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts
  puts "usage: #{File.basename(__FILE__)} -option args"
  ins_meths = ZendeskGilmationUtils.instance_methods(false)
  puts "----------------"
  puts "Options are:"
  ins_meths.each do | method |
    puts "-#{method}" if method =~ /^find/
  end
  puts "-help"
  puts "----------------"
  puts
  exit
elsif ARGV[0] =~ /^-/
  ZendeskGilmationUtils.new.send( ARGV[0].sub('-',''), *ARGV[1..-1] )
else
  #problem with the argument
  raise "Arguments [#{ARGV}] are not the correct format"
end