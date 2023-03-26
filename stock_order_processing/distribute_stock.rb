require 'yaml'
require 'csv'
require 'fileutils'

class DistributeStock

  # Read CSV files
  def initialize(stock_csv, orders_csv, magento_csv)
    @stock_level = read_stock stock_csv
    read_orders orders_csv
    @magento_stock_level = read_stock magento_csv
    @missing_zero_stock_skus = []
  end


  # Creates:
  #   usa_proccessing_in_stock.csv:     order_ids that can be fulfilled
  #   usa_proccessing_out_of_stock.csv: order_ids that cannot be fulfilled
  #   usa_remaining_stock.csv:          initial stock vs remaining stock
  #   usa_skus_gone_oos.csv:            skus that become OOS
  #   usa_all_skus_oos.csv:             skus that are OOS even if they already were
  #   usa_missing_zero_stock_skus:      skus in pending orders that were not on the list
  #   usa_missing_from_catalog_skus.csv skus known to magento but not on the list
  def distribute
    puts "distribute"
    buckets = @stock_level.clone

    no_stock = []
    no_stock_other = []
    stock = []

    @orders_list.each do |id, date|
      data = @orders[id]
      print "."
      #data.each do |sku, qty|
      #  puts "  before: #{sku} - #{qty} /  #{buckets[sku]}"
      #end
      if probe_stock(buckets, data)
        use_stock(buckets, data)
        stock << {'order_id' => id, 'date' => date.strftime('%m/%d/%y %H:%M:%S') }

        #data.each do |sku, qty|
        #  puts "  after: #{sku} - #{qty} /  #{buckets[sku]}"
        #end

      else
        skus = order_skus_list(id)
        if /^300/ =~ id
          no_stock << {'order_id' => id, 'date' => date.strftime('%m/%d/%y %H:%M:%S'), 'skus' => skus }
        else
          no_stock_other << {'order_id' => id, 'date' => date.strftime('%m/%d/%y %H:%M:%S'), 'skus' => skus }
        end
      end
    end

    puts

    save_csv(stock, 'usa_proccessing_in_stock.csv', false)
    puts 'usa_proccessing_in_stock.csv created'
    save_csv(no_stock_other, 'usa_proccessing_out_of_stock_other.csv', false)
    puts 'usa_proccessing_out_of_stock_other.csv created'
    save_csv(no_stock, 'usa_proccessing_out_of_stock.csv', false)
    puts 'usa_proccessing_out_of_stock.csv created'
    stock_usage = []
    in_stock_to_out_of_stock = []
    out_of_stock = []
    @stock_level.each do |sku, qty|
      stock_usage << {
        'sku' => sku,
        'before' => qty,
        'after' => buckets[sku]
      }
      if qty > 0 && buckets[sku] <= 0
        in_stock_to_out_of_stock << {
          'sku' => sku,
          'before' => qty,
          'after' => buckets[sku]
        }
      end
      if buckets[sku] <= 0
        out_of_stock << {
          'sku' => sku,
          'before' => qty,
          'after' => buckets[sku]
        }
      end
    end
    save_csv(stock_usage, 'usa_remaining_stock.csv')
    puts 'usa_remaining_stock.csv created'
    save_csv(in_stock_to_out_of_stock, 'usa_skus_gone_oos.csv')
    puts 'usa_skus_gone_oos.csv created'
    save_csv(out_of_stock, 'usa_all_skus_oos.csv')
    puts 'usa_all_skus_oos.csv created'
    missing_zero_stock_skus_hash = @missing_zero_stock_skus.collect do | sku |
      { 'sku' => sku }
    end
    save_csv(missing_zero_stock_skus_hash, 'usa_missing_zero_stock_skus.csv')
    puts 'usa_missing_zero_stock_skus.csv'

    missing_from_catalog = []
    @magento_stock_level.each do |sku, qty|
      unless @stock_level[sku]
        missing_from_catalog << { 'sku' => sku }
      end
    end
    save_csv(missing_from_catalog, 'usa_missing_from_catalog_skus.csv')
    puts 'usa_missing_from_catalog_skus.csv created'

    buckets_csv = []
    buckets.each do |sku, qty|
      buckets_csv << { 'sku' => sku, 'qty' => qty }
    end
    save_csv(buckets_csv, 'usa_remaining_stock_after_processing_applied.csv', false)
    puts 'usa_remaining_stock_after_processing_applied.csv created'

    check_results(stock, no_stock, no_stock_other, stock_usage, in_stock_to_out_of_stock, out_of_stock, missing_zero_stock_skus_hash, missing_from_catalog)
  end

  def order_skus_list(id)
    @orders[id].keys.join " "
  end

  def probe_stock(stock_levels, line_items)
    result = true
    line_items.each do |sku, qty|
      unless available = stock_levels[sku]
        @missing_zero_stock_skus << sku unless @missing_zero_stock_skus.include?(sku)
        available = 0
      end
      if qty > available
        result = false
        break
      end
    end

    result
  end

  def use_stock(stock_levels, line_items)
    line_items.each do |sku, qty|
      available = stock_levels[sku].nil? ? 0 : stock_levels[sku]
      if qty <= available
        stock_levels[sku] = stock_levels[sku].nil? ? 0 : stock_levels[sku] - qty
      end
    end
  end

  def read_stock(file)
    puts "read_stock(#{file})"
    stock_level = {}
    stock_level_reserved = {}
    CSV.foreach(file, { :headers => true }) do | data |

      sku = data['SKU']
      type = data['ORDERED']
      qty = data['STOCK'].to_i

      stock_level_reserved[sku] = 0 if stock_level_reserved[sku].nil?
      stock_level[sku] = 0 if stock_level[sku].nil?

      if type.nil? || type.empty?
        stock_level[sku] += qty
      else
        stock_level_reserved[sku] += qty
      end
    end

    stock_level_reserved.each do |sku, qty|
      unless stock_level[sku].nil? || qty == 0
        prev = stock_level[sku]
        stock_level[sku] -= qty
        puts "WARNING: #{sku} stock changed from #{prev} to #{stock_level[sku]}"
      end
    end

    stock_level
  end

  def read_orders(file)
    puts "read_orders(#{file})"
    # Order line items
    @orders = {}
    # Orders sorted by date
    @orders_list = {}
    total_skus = 0
    CSV.foreach(file, { :headers => true }) do | data |

      id = data['ORDER NUMBER'].gsub('AFG', '')
      unless @orders[id]
        @orders[id] = {}
      end
      sku = data['SKU']
      qty = data['ORDER QTY'].to_i
      date = DateTime.strptime(data['ORDER DATE'], '%m/%d/%y %H:%M:%S')

      total_skus += qty if id =~ /^300/
      @orders[id][sku] = qty
      @orders_list[id] = date
    end

    @orders_list = @orders_list.sort_by { |id, date| date }

    puts "Total skus in open orders #{total_skus}"
    @orders
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

  def check_results(stock, no_stock, no_stock_other, stock_usage, in_stock_to_out_of_stock, out_of_stock, missing_zero_stock_skus_hash, missing_from_catalog)
    puts
    used = {}
    orders_in_stock = []
    all_orders_distributed = {}
    @orders.each do | id, data|
      all_orders_distributed[id] = false
    end
    puts "Checking that there's no missed or extra order..."
    stock.each do |o|
      id = o['order_id']
      orders_in_stock << id
      if all_orders_distributed[id].nil?
        puts "ERROR: order #{id} not in the original list"
      else
        all_orders_distributed[id] = true
      end
      @orders[id].each do |sku, qty|
        used[sku] ||= 0
        used[sku] += qty
      end
    end

    no_stock.each do |o|
      id = o['order_id']
      if all_orders_distributed[id].nil?
        puts "ERROR: order #{id} not in the original list"
      else
        all_orders_distributed[id] = true
      end
    end

    no_stock_other.each do |o|
      id = o['order_id']
      if all_orders_distributed[id].nil?
        puts "ERROR: order #{id} not in the original list"
      else
        all_orders_distributed[id] = true
      end
    end

    all_orders_distributed.each do |id, value|
      unless value
        echo "ERROR order #{id} not distributed in any stock or out-of-stock csv"
      end
    end

    puts "Checking that usa_remaining_stock.csv skus usage matches the remaining stock..."
    compare_stock_usages(stock_usage, used)
    puts "Checking that usa_skus_gone_oos.csv skus usage matches the remaining stock..."
    compare_stock_usages(in_stock_to_out_of_stock, used)

    puts "Checking that usa_proccessing_out_of_stock.csv does not intersect usa_proccessing_in_stock.csv..."
    no_stock.each do |o|
      if orders_in_stock.include? o
        echo "  ERROR in usa_proccessing_out_of_stock.csv: #{o} distributed and not distributed"
      end
    end
    puts "Checking that usa_proccessing_out_of_stock_other.csv does not intersect usa_proccessing_in_stock.csv..."
    no_stock_other.each do |o|
      if orders_in_stock.include? o
        echo "  ERROR in usa_proccessing_out_of_stock_other.csv: #{o} distributed and not distributed"
      end
    end

    puts "ALL CHECKS DONE"
  end

  private

  def compare_stock_usages(usage, used)
    usage.each do |data|
       sku = data['sku']
       before = data['before']
       after = data['after']
       distributed = used[sku] ? used[sku] : 0
       unless distributed + after == before
         puts "  ERROR distributing #{sku}: #{distributed} + #{after} <> #{before}"
       end
    end
  end

end

if ARGV.size < 3 || ARGV[0] =~ /\-help/
  #  ruby distribute_stock.rb stock_levels.csv warehouse_open_orders.csv
  puts
  puts "usage: #{File.basename(__FILE__)} stock_levels.csv warehouse_open_orders.csv stock_magento.csv"
  puts "  stock_magento.csv is the result (changing its header) of"
  puts "    php warehouses_tools.php --getLocalStock 3,AFG | cut -d "," -f 3,5"
  puts
  if ARGV.size < 3
    puts "Expected 3 arguments and you supplied [#{ARGV.size}] arguments - [#{ARGV}]"
    puts
  end
  exit
elsif ARGV[0] =~ /\.csv$/
  # naive check of the first arg is OK
  dist = DistributeStock.new(*ARGV)
  dist.distribute
else
  #problem with the arg format
  puts "Argument [#{ARGV[0]}] does not appear to be the expected format"
  exit
end