require 'json'
require 'fileutils'
require 'thor'

# Some json manipulation and
# testing methods
class Json < Thor
  include FileUtils::Verbose

  def self.exit_on_failure?
    true
  end

  # Load the given json file to make sure that the structure is correct and that 
  # there are no parse errors
  desc "load_json", "Load the given json file to test the structure is correct"
  option :file, :type => :string, :required => true, :aliases => "-f" 
  def load_json
    throw("No json file exists at [#{options[:file]}]") unless File.exists?(options[:file])
    puts "## Start of JSON ##"
    loaded = JSON.load(File.open(options[:file]))
    puts loaded.to_json
    puts "## End of JSON ##"
  end
end
