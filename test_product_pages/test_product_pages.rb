#require 'rubygems'
require 'csv'
require 'net/http'
require 'uri'

class TestProductPages

  def initialize(csv_file)
    @products = {}

    CSV.foreach(csv_file, { :headers => true }) do | data |
      sku = data['product_sku']
      @products[sku] = {
        'expected_url' => data['expected_url'],
        'websites'     => extract_websites(data['websites'] ? data['websites'].split(':') : []),
        'num_images'   => data['num_images'].to_i,
        'variants'     => data['variant_skus'] ? data['variant_skus'].split(':') : [],
        'real_url'     => data['magento_url'],
        'images'       => data['images'] ? data['images'].split(':') : []
      }
    end

    @sites = {
      'uk' => 'http://www.morphsuits.co.uk/',
      'us' => 'http://www.morphsuits.com/',
      'de' => 'http://www.morphsuitsdeutschland.com/',
      'ca' => 'http://www.morphsuits-canada.com/',
      'au' => 'http://www.morphsuits.com.au/',
      'nz' => 'http://www.morphsuits.co.nz/',
      'nl' => 'http://www.morphsuits.nl/',
      'fr' => 'http://www.morphsuits.fr/',
      'es' => 'http://www.morphsuits.es/',
      'it' => 'http://www.morphsuits.it/'
    }

    #puts @products.to_s
  end

  def extract_websites(list)
    result = []
    list.each do |elm|
      if elm == 'eu'
         result << 'de' 
         result << 'nl'
         result << 'fr'
         result << 'es'
         result << 'it'
      else
         result << elm
      end
    end

    result
  end

  def execute_test
    @products.each do |sku, data|
      if data['websites'].empty?
        puts "ERROR: #{sku} not in any website"
      else
        puts "ERROR: #{sku} url mismatch [#{data['expected_url']}] [#{data['real_url']}] not in any websites" unless data['expected_url'] == data['real_url']
        puts "ERROR: #{sku} has zero loaded images" if data['images'].size == 0
        puts "WARN:  #{sku} expected images [#{data['num_images']} differs with the loaded ones ["+data['images'].size.to_s+"]" unless data['num_images'] == data['images'].size 
        unless data['real_url'].nil?
          data['websites'].each do |website|
            base = @sites[website].nil? ? '' : @sites[website].strip
            if base.nil? || base.empty?
              puts "ERROR: #{sku} website #{website} not found"
            else
              url = base + data['real_url']
              check(sku, base, data['real_url'], data['images'], data['variants'])
            end
          end  
        end
      end
    end
  end

  def check(sku, domain, product_page, images, variants)
    result = check_status_code(domain+product_page, images)
    puts "Check [#{sku}] #{domain}#{product_page} " + (result['success'] ? 'OK' : 'Error ' + result['code'])
    unless result['success']
      result['msgs'].each do |msg|
        puts "  Error: "+msg
      end
    end
    
    images.each do |image|
      res = domain+'media/catalog/product'+image
      result = check_status_code(res)
      puts "  "+res+" "+(result['success'] ? 'OK' : 'Error '+result['code'])
    end
  end

  def check_status_code(resource, expected_data = nil)
    url = URI.parse(resource + "?extra=test")
    req = Net::HTTP::Get.new(url.path)
    response = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

    status = { 'success' => true, 'code' => response.code, 'msgs' => [] }

    if response.code.to_i >= 400
      status['success'] = false
    else
      status['success'] = true
      unless expected_data.nil? 
        expected_data.each do |find|
          status['msgs'] << "[#{find}] not found" unless response.body.include?(find)
        end
      end
    end

    status
  end

end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts "usage: #{File.basename(__FILE__)} csv_file"
  puts "File list is NOT optional...not specifying a list will cause this message to be rendered"
  exit
elsif ARGV[0] =~ /\.csv$/
  check = TestProductPages.new(ARGV[0])
  check.execute_test
else
  #problem with the argument
  raise "Argument [#{ARGV[0]} is not the correct format"
end

