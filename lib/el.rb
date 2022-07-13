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

require 'el/trait'
require 'el/routable'
require 'el/pluggable'

require 'el/entity'
require 'el/repository'
require 'el/model'
require 'el/application'

# OOP / Meta
require_relative 'el/memoize'

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
require_relative 'el/hash_view'
