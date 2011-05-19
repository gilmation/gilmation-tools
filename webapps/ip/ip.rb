  # IP
  require 'sinatra/base'

  class Ip < Sinatra::Base

    use Rack::Auth::Basic do |username, password|
      username == 'admin' && password == 'secret'
    end

    # Return the IP
    get '/' do
      request.ip
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
  
