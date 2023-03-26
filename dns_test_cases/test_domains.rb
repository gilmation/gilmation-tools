require 'rubygems'
require 'dnsimple'
require 'net/https'
require '../common/common.rb'

class CheckDomains
  include Common

  def initialize
    _init_dnsimple
  end

  def check(domain_list_yml)
    domains = YAML.load_file(domain_list_yml)
    result = domains['domains'].select do | domain, attributes |
      check_dns_resolution(domain, attributes['ip']) || check_status_code(domain, attributes['code'])
    end
    if result.size > 0
      puts "Oops, we have a problem with these domains:"
      puts result
    end
  end

  def check_assets(asset_list_yml)
    assets = YAML.load_file(asset_list_yml)
    result = assets['morphsuits'].select do | domain, cloudfront_domain |
      dnsimple_domain = DNSimple::Domain.find(domain)
      dnsimple_records = DNSimple::Record.all(dnsimple_domain)
      dnsimple_records.none? do | dnsimple_record |
        puts "Domain [#{domain}], Name [#{dnsimple_record.name}], Content [#{dnsimple_record.content}]"
        dnsimple_record.record_type =~ /CNAME/ && dnsimple_record.content == cloudfront_domain
      end
    end
    if result.size > 0
      puts "Oops, we have a problem with these assets:"
      puts result
    end
  end

  def check_status_code(domain, code)
    http = Net::HTTP.new(domain)
    request = Net::HTTP::Get.new("/?extra=test")
    response = http.request(request)
    puts "Checked HTTP status code for [#{domain}], Expected [#{code}], Actual [#{response.code}]"
    result = nil
    if response.code != code.to_s
      puts "Returning Http status code failure for [#{domain}]"
      result = domain
    end
    result
  end

  def check_dns_definition
    # Is this necessary ? 
  end

  def check_dns_resolution(domain, ip)
    command = "dig #{domain} +short | grep -v morph | grep -v foul"
    dns_result = `#{command}`
    puts "Checked DNS resolution for [#{domain}], result [#{dns_result}]"
    if dns_result.nil? || !dns_result.include?(ip)
      result = domain
    end
    puts "Returning DNS Failure [#{result}]" if result
    result
  end

end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts "usage: #{File.basename(__FILE__)} your_list_of_domains.yml"
  puts "OR"
  puts "usage: #{File.basename(__FILE__)} -check-assets your_list_of_assets.yml"
  puts "File list is NOT optional...not specifying a list will cause this message to be rendered"
  exit
elsif ARGV[0] =~ /\.yml$/
  check_domains = CheckDomains.new
  check_domains.check(ARGV[0])
elsif ARGV[0] =~ /\-check-assets/
  check_domains = CheckDomains.new
  check_domains.check_assets(ARGV[1])
else
  #problem with the argument
  raise "Arguments [#{ARGV} are not the correct format"
end

