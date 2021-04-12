module Drn
  module Mentoring
    # A Dry::Container that represents the application, and provides dependency injection.
    class Application < Dry::System::Container
      configure do |config|
        config.root = Pathname("#{__dir__}/../../..")

        config.auto_register = 'lib/drn/mentoring'
      end

      load_paths!('lib/drn/mentoring')
    end
  end
end
