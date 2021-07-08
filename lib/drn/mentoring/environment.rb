require 'pp'
require 'cgi'
require 'set'
require 'json'
require 'yaml'
require 'logger'
require 'pathname'
require 'forwardable'

require 'bundler/setup'
Bundler.require

# Monkey patches
require_relative 'core_ext'

require_relative 'trait'

# Utility methods
require_relative 'utils'
require_relative 'sql_utils'

# Application state
require_relative 'application'
