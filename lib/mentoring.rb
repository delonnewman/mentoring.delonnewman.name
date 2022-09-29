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
require 'el/advice'
require 'el/advising'
require 'el/memoize'

# Templating
require 'el/template_helpers'
require 'el/templates'
require 'el/template'
require 'el/templating'

# Messaging
require 'el/messenger'

# Request Dispatch
require 'el/json_response'

require 'el/authenticable'
require 'el/controller'
require 'el/view'
require 'el/template_view'
require 'el/page_view'
require 'el/hash_view'
