#
# Module namespace to 
# identify the Utils as a part
# of the Gilmation code base
# Different name is used to avoid
# a clash with the Gilmation Thor 
# class
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
    #
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

  end
end
