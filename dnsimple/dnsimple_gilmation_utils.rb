require 'fileutils'
require 'dnsimple'
require 'csv'
require 'net/http'
require '../common/common.rb'

#
# Use the new dnsimple v2 API
# Gem installed with
# $ gem install dnsimple --pre
#
class DnsimpleGilmationUtils
  include FileUtils::Verbose
  include Common

  def initialize
    _init_dnsimple
  end

  def find_domains_ips
    _output( _get_all_domains_ips, './dnsimple_domains_ips.csv', ['domain','ip'] )
  end

  def find_ips_domains
    _output( _get_all_ips_domains, './dnsimple_ips_domains.csv' )
  end

  def find_status_all_domains
    _output( _get_status_all_domains, './dnsimple_status_all_domains.csv', ['domain','registered','nameservers'] )
  end

  def _get_status_all_domains
    uri = URI( "https://api.zone.vision/" )
    @http_client = Net::HTTP.new(uri.host, uri.port)
    @http_client.use_ssl = true
    @dnsimple_client.domains.all_domains(@dnsimple_account_id).data.inject({}) do | memo, domain |
      request = Net::HTTP::Get.new( URI( "https://api.zone.vision/nameservers/#{domain.name}" ) )
      request.set_content_type('application/json')
      response = @http_client.request( request , "Oops" ).body
      nameservers = response && response =~ /{\"error\":\"Domain not found\"}/ ? 'Not Resolving' : 'Resolving'
      # Delete the not-resolving domain
      puts "Statuses of [#{domain.name}] were [#{domain.state}], [#{nameservers}]"
      if nameservers =~ /Not/
        puts "-------------------------"
        puts "Deleting [#{domain.name}]"
        #@dnsimple_client.domains.delete_domain(@dnsimple_account_id, domain.name)
        puts "Deleted [#{domain.name}]"
        puts "-------------------------"
      end
      memo[domain.name] = [ domain.state, nameservers ]
      memo
    end
  end

  def _get_all_domains_ips
    @dnsimple_client.domains.all_domains(@dnsimple_account_id).data.inject({}) do | memo, domain |
      puts "Searching for an A record for [#{domain.name}], [#{domain.state}]"
      #
      # Can't find a good way to do this - as the following returns all records
      # @dnsimple_client.zones.records(@dnsimple_account_id, domain.name, query: { type: 'A' })

      # puts "Domain has records [#{ @dnsimple_client.zones.records(@dnsimple_account_id, domain.name).total_entries > 0 ? @dnsimple_client.zones.records(@dnsimple_account_id, domain.name).total_entries : 0 }]"
      # records = DNSimple::Record.all(domain, {:query => { :type => 'A' } })
      # if records.empty?
      #   puts "Cannot find A record for [#{domain.name}]"
      #   memo[domain.name] = 'Not Found'
      # else
      #   records.each do | record |
      #     puts "Found A record for [#{domain.name}], [#{record.content}]"
      #     memo[_get_fqdn(record, domain)] = record.content
      #   end
      # end
      memo
    end
  end

  def _get_all_ips_domains
    @dnsimple_client.domains.all_domains(@dnsimple_account_id).data.inject({}) do | memo, domain |
      puts "Searching for an A record for [#{domain.name}]"


      # records = DNSimple::Record.all(domain, {:query => { :type => 'A' } })
      # if records.empty?
      #   puts "Cannot find A record for [#{domain.name}]"
      #   memo['Not Found'] ||= []
      #   memo['Not Found'] << domain.name
      # else
      #   records.each do | record |
      #     name = _get_fqdn(record, domain)
      #     ip = record.content
      #     puts "Found A record for [#{name}], [#{ip}]"
      #     memo[ip] ||= []
      #     memo[ip] << name
      #   end
      # end
      memo
    end
  end

  def _get_fqdn(record, domain)
    record.name.blank? ? domain.name : "#{record.name}.#{domain.name}"
  end

  def _output(results, filename, headers=nil)
    rm_r(filename) if File.exists?(filename)
    CSV.open(filename, 'a') do | csv |
      csv << headers if headers
      results.sort.each do | key, value |
        if value.is_a?( Array )
          csv << value.sort.insert(0, key)
        else
          csv << [key, value]
        end
      end
    end
  end
end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts
  puts "usage: #{File.basename(__FILE__)} -option args"
  ins_meths = DnsimpleGilmationUtils.instance_methods(false)
  puts "----------------"
  puts "Options are:"
  ins_meths.each do | method |
    puts "-#{method}" if method =~ /^find/
  end
  puts "-help"
  puts "----------------"
  puts "This script gets the dnsimple domains and A record IPs and outputs them - the order is configurable (see methods)"
  puts "The name of the option that you want to run is NOT optional...not specifying an option will cause this message to be rendered"
  puts
  exit
elsif ARGV[0] =~ /^-/
  DnsimpleGilmationUtils.new.send( ARGV[0].sub('-',''), *ARGV[1..-1] )
else
  #problem with the argument
  raise "Arguments [#{ARGV}] are not the correct format"
end
