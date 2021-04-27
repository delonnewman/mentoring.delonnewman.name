module Drn
  module Mentoring
    class Application
      def success_url(product)
        if product.recurring?
          "http://#{ENV['DOMAIN']}/success.html?session_id={CHECKOUT_SESSION_ID}"
        else
          "http://#{ENV['DOMAIN']}/session/new?session_id={CHECKOUT_SESSION_ID}"
        end
      end

      def session_data(product)
        data = {
          success_url: success_url(product),
          cancel_url: 'http://localhost:9393',
          payment_method_types: ['card'],
          mode: product.checkout_mode,
        }
        
        if not product.recurring?
          data
        else
          data.merge!(line_items: [{ quantity: 1, price: product.price_id }])
        end
      end

      def success_data(product, session)
        if product.recurring?
          { type: 'complete', sessionId: session.id }
        else
          { type: 'setup', sessionId: session.id, setupIntent: session.setup_intent }
        end
      end
    end
  end
end
