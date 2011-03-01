$TESTING=true

require 'thor'
require 'thor/group'
require 'rubygems'

$thor_runner = true

# Set shell to basic
Thor::Base.shell = Thor::Shell::Basic
