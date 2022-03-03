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

# Monkey patches, we'll keep these to a minimum
require_relative 'el/core_ext'
require_relative 'el/core'

# OOP
require_relative 'el/trait'

# Application State & DI
require_relative 'el/application'

# Utility methods
require_relative 'el/utils'
require_relative 'el/utils/string_utils'
require_relative 'el/utils/time_utils'
require_relative 'el/utils/numeric_utils'
require_relative 'el/sql_utils'

# Templating
require_relative 'el/template_helpers'
require_relative 'el/templatable'
require_relative 'el/templated'
require_relative 'el/template'

# Messaging
require_relative 'el/mailer'

# Model
require_relative 'el/entity'
require_relative 'el/repository'

# Request Dispatch
require_relative 'el/json_response'
require_relative 'el/router'
require_relative 'el/entity_controller'
require_relative 'el/admin_controller'
