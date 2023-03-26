#require 'rubygems'
require 'csv'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'open-uri'

class TestGoogleMerchantsFeed

  def initialize(feed_url)
    @feed= {}

    xml_doc = Nokogiri::XML(File.exists?(feed_url) ? File.open(feed_url) : open(feed_url))
    rows = xml_doc.xpath("//item")
    rows.each do |row|
      sku = row.xpath("g:id").inner_text
      @feed[sku] = {
        url: row.at('link').inner_text,
        name: row.at('title').inner_text,
        price: format_price(row.xpath('g:price').inner_text),
        sale_price: format_price(row.xpath('g:sale_price').inner_text)
      }
    end
    puts "Feed retrieved ("+rows.size.to_s+" entries)"
  end

  def execute_test(filter = nil)
    checked_urls = {}

    @feed.each do |sku, data|
      next if !filter.nil? && !(sku =~ /#{filter}/)
      if checked_urls[data[:url]] 
        if checked_urls[data[:url]] == data[:price]
          puts "Checked #{sku}: ALREADY DONE"
        else
          puts "WARNING: "+data[:url]+" retrieved more than once with inconsistent pricing"
        end
        next
      end
      existing_price = collect_product_page_data(data[:url])
      result = existing_price == data[:price]
      puts "Checked #{sku} - ["+data[:url]+"]: [#{existing_price}] vs ["+data[:price].to_s+"] "+(result ? "OK" : "DIFFER")
      
      checked_urls[data[:url]] = existing_price
    end
  end

  def collect_product_page_data(url)
    begin
      doc = Nokogiri::HTML(open(url))
      price = doc.xpath('//div[@id="product-price"]/span/span[@class="price"]') 
      if price.empty?
        price = doc.xpath('//div[@id="product-price"]/div/span[@class="regular-price"]')
      end
      result = price ? format_price(price.inner_text) : -1.00
    rescue => e
      puts "ERROR loading #{url}: "+e.message  
      result = -2.00
    end
    
    result

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

  private

  def format_price(price_str)
    price_str.gsub(/[^0-9\.]/, '').to_f
  end
end

if ARGV.size < 1 || ARGV[0] =~ /\-help/
  puts "usage: #{File.basename(__FILE__)} feed_url (filter)"
  puts "File list is NOT optional...not specifying a list will cause this message to be rendered"
  exit
elsif ARGV.size > 0 
  filter = ARGV.size == 2 ? ARGV[1] : nil
  check = TestGoogleMerchantsFeed.new(ARGV[0])
  check.execute_test(filter)
else
  #problem with the argument
  raise "Argument [#{ARGV[0]} is not the correct format"
end

