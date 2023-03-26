require 'fileutils'
require 'csv'
require '../common/common.rb'
require 'google_drive'

class QualarooGA
  include FileUtils::Verbose
  include Common

  def initialize
    _init_google
    @surveys = { 'marvel_uk' => '1PoWaGGc9UvuJWtCwweB7P5DViLGP7SASBqAj7ZpeHZI', 'costumes_uk' => '1n-jClzlBeAB_TpDBmivg8icdeNGvgvuhp6JiMxYGSro', 
      'costumes_us' => '1Be5z-5cyWsZ10xxY0W4IgSKG87JxDVOhYeQwQwtDONs', 'dropship_us' => '1T_zJ1DBg-_G5JrxBajUjWebsi3bPF8Ya72vcZbBMFr8', 
      'rahat_us' => '1B9LJT0ekYJXD-JbPVKnOddgW6mN7hGTufwWnQ216CiI' }
    # @surveys = { 'rahat_us' => '1B9LJT0ekYJXD-JbPVKnOddgW6mN7hGTufwWnQ216CiI' }
  end

  def run
    session = GoogleDrive.login(@google_user, @google_pwd)
    @surveys.each do | survey_name, spreadsheet_key |
      filename = "./qualaroo_#{survey_name}_output.csv"
      headers = ['time','page','question_title','answer']
      raise "Oops [#{filename}] should exist" unless File.exists?(filename)

      spreadsheet = session.spreadsheet_by_key(spreadsheet_key)
      ws_new = spreadsheet.add_worksheet("#{survey_name}_#{Time.new.strftime("%d_%m_%Y")}")
      ws_new_list = ws_new.list
      ws_new_list.keys = headers

      CSV.foreach(filename, headers: true) do | data |
        ws_new_list.push(data)
      end
      ws_new.save
      #spreadsheet.worksheets[0].delete if spreadsheet.worksheets[0]
    end
  end
end

if ARGV[0] =~ /\-help/
  #  ruby qualaroo.rb
  puts
  puts "usage: #{File.basename(__FILE__)} [-help]"
  puts "Uploads the results from a number of Qualroo Surveys to GA from local ./qualaroo_$NAME_output.csv files"
  exit
else
  #no problem with the arg format
  QualarooGA.new.run
end
