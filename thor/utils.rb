#
# Module namespace to
# identify the Utils as a part
# of the Gilmation code base
# A different name is used to avoid
# a namespace clash with the Gilmation
# Thor class
#
module Gilm
  #
  # Utils for common fuctionality
  # used in various thor files
  #
  module Utils

    #
    # Recursive method that will print out all the elements
    # that are contained within a Hash, recursing into any
    # Hashes that it finds along the way.
    # @param key [String] the key for this string_or_hash
    # @param string_or_hash [String] the String or Hash object
    def show_string_hash(key, string_or_hash)
      case string_or_hash
      when String then puts "[#{key}] is [#{string_or_hash}]"
      when Hash then string_or_hash.each { | key, value | show_string_hash(key, value) }
      end
    end

    # Load the config or throw an error
    # @param config [String] the absolute path to a config file
    def load_config(config)
      # load the config
      throw "Cannot process config file [#{config}]" unless config && File.exists?(config)
      loaded_config = YAML.load_file(config)
      throw "Cannot proceed with loaded config file [#{loaded_config}]" if loaded_config.nil? || loaded_config.empty?
    end

    #
    # Recursive method that will check all the elements in a
    # deployed directory are equal to those in a source
    # directory - if this is not the case then a warning
    # will be printed.
    # @param source_path [String] the source_path
    # @param deployed_path [String] the deployed_path
    def check_files(source_path, deployed_path)
      return unless File.exists?(deployed_path)

      Dir.foreach(deployed_path) do | deployed_file |
        # pass on this file if we have a self or parent reference
        next if ['.', '..'].include?(deployed_file)

        source_file = File.join(source_path, deployed_file)
        deployed_file = File.join(deployed_path, deployed_file)

        if(File.exists?(source_file))
          if(File.directory?(deployed_file))
            # we need recursion if the File is a directory
            check_files(source_file, deployed_file)
          else
            unless(uptodate?(source_file, deployed_file) ||
              File.size(source_file) == File.size(deployed_file))
              puts("[#{deployed_file}] is newer and a different size than the source control version")
            end
          end
        else
          puts("[#{source_file}] does not exist, but a deployed version exists")
        end
      end
    end

  end
end
