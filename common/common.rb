require 'rubygems'

module Common

  # Load the given json file to make sure that the structure is correct and that
  # there are no parse errors
  # @param path String the (relative or absolute) path to the file that we want to load
  def _load_json(path)
    throw("No json file exists at [#{path}]") unless path && File.exists?(path)
    JSON.load(File.open(path))
  end

  def _get_login(service)
    begin
      logins = YAML.load_file(File.join(ENV['HOME'], '.gilmation', '.logins.yml'))
    rescue
      message = "Can't find the logins.yml file"
      puts message
      raise
    end
    service_values = logins['logins'][service]
    unless service_values
      puts "Cannot find the service values for [#{service}]"
      raise
    end
    return logins['logins'][service]
  end

  def _init_google
    login = _get_login('google')
    @google_user = login['user']
    @google_pwd = login['pwd']
  end

  def _init_qualaroo
    login = _get_login('qualaroo')
    @api_key = login['api_key']
    @api_secret = login['api_secret']
  end

  def _init_dnsimple
    login = _get_login('dnsimple')
    @dnsimple_client = Dnsimple::Client.new(access_token: login['api_token'])
    @dnsimple_account_id = login['account_id']
  end

  def _init_zendesk
    login = _get_login('zendesk')
    @zendesk_user = login['user']
    @zendesk_token = login['token']
  end

end
