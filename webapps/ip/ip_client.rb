require 'open-uri'
require 'pp'
open('http://localhost:4567') do |f|
  puts f.gets
end

