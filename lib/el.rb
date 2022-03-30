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

require 'el/entity'
require 'el/repository'
require 'el/model'

require 'el/trait'
require 'el/routable'

# OOP / Meta
require_relative 'el/memoize'
require_relative 'el/pluggable'

# Templating
require_relative 'el/template_helpers'
require_relative 'el/templates'
require_relative 'el/template'
require_relative 'el/templating'

# Messaging
require_relative 'el/messenger'

# Request Dispatch
require_relative 'el/json_response'

require_relative 'el/authenticable'
require_relative 'el/controller'
require_relative 'el/view'

# Application State & DI
require_relative 'el/application'
