# frozen_string_literal: true

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

# OOP
require_relative 'el/trait'

# Utility methods
require_relative 'el/utils'
require_relative 'el/sql_utils'

# Templating
require_relative 'el/template_helpers'
require_relative 'el/templatable'
require_relative 'el/templated'
require_relative 'el/template'

# Messaging
require_relative 'el/messenger'

# Model
require_relative 'el/entity'
require_relative 'el/repository'

# Request Dispatch
require_relative 'el/json_response'

require_relative 'el/authenticable'
require_relative 'el/controller'
require_relative 'el/view'

# Application State & DI
require_relative 'el/application'
