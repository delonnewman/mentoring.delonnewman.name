require 'rack/contrib/try_static'

module Drn
  module Mentoring
    # Represents the application
    class Application < El::Application
      root_path File.join(__dir__, '..', '..', '..')

      # Components
      class StripeClient < El::Record
        require :key

        def start
          Stripe.api_key = key
        end

        def stop
        end
      end

      system stripe: StripeClient[key: ENV.fetch('STRIPE_KEY')]
    end
  end
end
