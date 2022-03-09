# frozen_string_literal: true

require 'rack/contrib/try_static'

require_relative 'utils'
require_relative 'templatable'
require_relative 'templated'
require_relative 'entity'
require_relative 'repository'

require_relative 'application/dependency'
require_relative 'application/servicable'
require_relative 'application/service'
require_relative 'application/routes'
require_relative 'application/router'
require_relative 'application/entity'

require_relative 'application/class_methods'
require_relative 'application/settings'
require_relative 'application/loader'
require_relative 'application/base'
