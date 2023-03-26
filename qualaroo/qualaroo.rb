require 'json'
require 'fileutils'
require 'csv'
require '../common/common.rb'

class Qualaroo
  include FileUtils::Verbose
  include Common

  def initialize
    _init_qualaroo
    @marvel_uk = ['126749', '126748', '126747', '126746', '120057']
    @costumes_uk = ['127246', '127244', '127242', '127238', '127232']
    @costumes_us = ['127696', '127697', '127695', '127694', '127693']
    @dropship_us = ['129129', '129131', '129132', '129135', '129137']
    @rahat_us = ['129283', '129284', '129285', '129204']
    @surveys = { 'marvel_uk' => @marvel_uk, 'costumes_uk' => @costumes_uk, 'costumes_us' => @costumes_us, 
      'dropship_us' => @dropship_us, 'rahat_us' => @rahat_us }
  end

  def run
    @surveys.each do | survey_name, survey_ids |
      filename = "./qualaroo_#{survey_name}_output.csv"
      headers = ['time','page','question_title','answer']
      rm_r(filename) if File.exists?(filename)
      CSV.open(filename, 'a') do | csv |
        csv << headers
        survey_ids.each do |survey_id|
          json_string = `curl -u #{@api_key}:#{@api_secret} https://app.qualaroo.com/api/v1/nudges/#{survey_id}/responses.json`
          json = JSON.parse(json_string)
          puts json
          json.each do | response |
            if answered_questions = response['answered_questions']
              answered_questions.each do | key, answered_question |
                answer = answered_question['answer'] =~ /Other/ ? "#{answered_question['answer']} - #{answered_question['comment']}" : answered_question['answer']
                csv << [response['time'], response['page'], answered_question['question_title'], answer]
              end
            end
          end
        end
      end
    end
  end
end

if ARGV[0] =~ /\-help/
  #  ruby qualaroo.rb
  puts
  puts "usage: #{File.basename(__FILE__)} [-help]"
  puts "Gets the answers from a number of Qualroo Surveys and outputs them to a local ./qualaroo_output.csv file"
  exit
else
  #no problem with the arg format
  Qualaroo.new.run
end
