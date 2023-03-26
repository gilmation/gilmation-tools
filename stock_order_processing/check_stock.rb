require 'yaml'
require 'csv'
require 'fileutils'

class CheckStock

  # Read CSV files
  def initialize(stock_csv, stock_api, stock_magento)
    @csv_stock_level = read_stock stock_csv
    @api_stock_level = read_stock stock_api
    @magento_stock_level = read_stock stock_magento
  end


  def compare
    result = []
    checked = []
    @csv_stock_level.each do |sku, qty|
      api_level = @api_stock_level[sku]
      checked << sku
      if api_level.nil? || api_level == '-'
        api_level = 'unknown'
        csv_api = ''
      else
        csv_api = qty - api_level
      end

      magento_level = @magento_stock_level[sku]
      if magento_level.nil? || magento_level == '-'
        magento_level = 'unknown'
        csv_magento = ''
      else
        csv_magento = qty - magento_level
      end

      if api_level.nil? || api_level == 'unknown' || magento_level.nil? || magento_level == 'unknown'
        api_magento = ''
      else
        api_magento = api_level - magento_level
      end

      result << { 'sku' => sku, 'csv' => qty, 'api' => api_level, 'magento' => magento_level, 'csv-api' => csv_api, 'csv-magento' => csv_magento, 'api-magento' => api_magento }
    end

    @api_stock_level.each do |sku, qty|
      next if checked.include? sku

      checked << sku
      magento_level = @magento_stock_level[sku]
      if magento_level.nil?
        magento_level = 'unknown'
        api_magento = ''
      else
        api_magento = qty - magento_level
      end

      result << { 'sku' => sku, 'csv' => 'unknown', 'api' => qty, 'magento' => magento_level, 'csv-api' => '', 'csv-magento' => '', 'api-magento' => api_magento }
    end

    @magento_stock_level.each do |sku, qty|
      next if checked.include? sku

      result << { 'sku' => sku, 'csv' => 'unknown', 'api' => 'unknown', 'magento' => qty, 'csv-api' => '', 'csv-magento' => '', 'api-magento' => '' }
    end

    save_csv(result, 'usa_stock_compare.csv', true)
  end

  private

  def read_stock(file)
    stock_level = {}
    CSV.foreach(file, { :headers => true }) do | data |

      sku = data['SKU']
      type = data['ORDERED']
      qty = data['STOCK'].to_i
      if stock_level[sku].nil?
        stock_level[sku] = qty
      else
        was = stock_level[sku]
        stock_level[sku] = type.nil? || type.empty? ? qty - was : was - qty
        puts "WARNING: #{sku} stock changed from #{was} to #{stock_level[sku]}"
      end
    end

    stock_level
  end

  def save_csv(lines, filename, header = true)
    FileUtils.rm_f(filename)
    CSV.open(filename, 'a') do | csv |
      i = 0
      keys = []
      lines.each do |line|
        if i == 0
          if header
            csv << line.keys
          end
          line.keys.each do |key|
            keys << key
          end
        end
        i += 1
        csv << line.values
      end
    end
  end

end

if ARGV.size < 3 || ARGV[0] =~ /\-help/
  #  ruby distribute_stock.rb stock_levels.csv warehouse_open_orders.csv
  puts
  puts "usage: #{File.basename(__FILE__)} stock_levels.csv stock_api.csv stock_magento.csv"
  puts "  stock_magento.csv is the result (changing its header) of"
  puts "    php warehouses_tools.php --getLocalStock 3,AFG | cut -d "," -f 3,5"
  puts "  stock_api.csv is the result (changing its header) of"
  puts "    php warehouses_tools.php --getRemoteStock 3 | grep -v \"BYSS\""
  puts
  if ARGV.size < 3
    puts "Expected 3 arguments and you supplied [#{ARGV.size}] arguments - [#{ARGV}]"
    puts
  end
  exit
elsif ARGV[0] =~ /\.csv$/
  # naive check of the first arg is OK
  check = CheckStock.new(*ARGV)
  check.compare
else
  #problem with the arg format
  puts "Argument [#{ARGV[0]}] does not appear to be the expected format"
  exit
end