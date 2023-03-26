require 'rubygems'
require 'yaml'
require 'net/http'
require 'uri'

class CheckResponse

  def initialize

  end

  def check(resource_list_yml)
    resources = YAML.load_file(resource_list_yml)
    result = resources['resources'].select do | resource, attributes |
      check_status_code(resource, 'http', attributes['code'].to_i, attributes['redirect'])
    end
    if result.size > 0
      puts "Oops, we have a problem with these resources:"
      puts result
    end
  end

  def check_status_code(resource, protocol, code, redirect)

    puts "Check status for [#{resource}]"

    if (resource =~ /^http/)
      res = resource
    else
      res = protocol + '://' + resource
    end
    url = URI.parse(res + "/?extra=test")
    req = Net::HTTP::Get.new(url.path)
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

    puts "Checked HTTP status code for [#{resource}], Expected [#{code}], Actual [#{response.code}]"

    failure = false
    result = nil

    if response.code != code.to_s
      failure = true
    end
    if (code == 301)
      redirected = response.header['Location']
      if (! redirected.include? redirect)
        failure=true
        puts "Checked 301-redirect Expected [#{redirect}], Actual [#{redirected}]"
      else
        puts "  Redirected to [#{redirected}]"
        failure = check_status_code(redirected, protocol, 200, nil) != nil
        puts
      end
    end
    if failure
      puts "Returning Http failure for [#{resource}]"
      puts
      result = resource
    end
    result
  end

end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts "usage: #{File.basename(__FILE__)} your_list_of_resources.yml"
  puts "File list is NOT optional...not specifying a list will cause this message to be rendered"
  exit
elsif ARGV[0] =~ /\.yml$/
  check_responses = CheckResponse.new
  check_responses.check(ARGV[0])
else
  #problem with the argument
  raise "Argument [#{ARGV[0]} is not the correct format"
end

