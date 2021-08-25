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
require_relative 'framework/core_ext'
require_relative 'framework/core'

# OOP
require_relative 'framework/trait'

# Utility methods
require_relative 'framework/utils'
require_relative 'framework/utils/string_utils'
require_relative 'framework/utils/time_utils'
require_relative 'framework/sql_utils'

# Templating
require_relative 'framework/template_helpers'
require_relative 'framework/templatable'
require_relative 'framework/templated'
require_relative 'framework/template'

# Messaging
require_relative 'framework/mailer'

# Model
require_relative 'framework/entity'
require_relative 'framework/repository'

# Controller
require_relative 'framework/authenticable'
require_relative 'framework/controller'
require_relative 'framework/entity_controller'
require_relative 'framework/admin_controller'
