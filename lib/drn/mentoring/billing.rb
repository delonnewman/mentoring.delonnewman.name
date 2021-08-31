module Drn
  module Mentoring
    class Billing
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def bill_mentoring_session!(session)
        return if session.checkout_session_id.nil?

        checkout = Stripe::Checkout::Session.retrieve(session.checkout_session_id)
        intent = Stripe::SetupIntent.retrieve(checkout.setup_intent)

        Stripe::PaymentIntent.create(
          amount: (session.cost.magnitude.to_f.round(2) * 100).to_i,
          currency: 'usd',
          payment_method_types: ['card'],
          customer: checkout.customer,
          payment_method: intent.payment_method
        )

        app.logger.info "SESSION BILLED: #{session.merge(billed_at: Time.now).inspect}"

        app.mentoring_sessions.update!(session.id, session.merge(billed_at: Time.now))
      end

      def find_or_create_customer!(user)
        if user.stripe_customer_id?
          Stripe::Customer.retrieve(user.stripe_customer_id)
        else
          customer = Stripe::Customer.create(
            name: current_user.name,
            email: current_user.email,
            description: current_user.stripe_description
          )

          app.users.add_stripe_customer_id!(id: current_user.id, stripe_id: customer.id)
        end
      end

      def create_checkout_session!(user, product)
        customer = find_or_create_customer!(user)

        Stripe::Checkout::Session.create(checkout_session_data(product, customer))
      end

      def checkout_success_url(product)
        if product.subscription?
          "http://#{app.settings['DOMAIN']}/products/#{product.id}/subscribe?session_id={CHECKOUT_SESSION_ID}"
        else
          "http://#{app.settings['DOMAIN']}/session/new?session_id={CHECKOUT_SESSION_ID}&product_id=#{product.id}"
        end
      end

      def checkout_session_data(product, customer)
        data = {
          success_url: checkout_success_url(product),
          cancel_url: "http://#{app.settings['DOMAIN']}",
          payment_method_types: ['card'],
          mode: product.checkout_mode,
          customer: customer.id
        }

        return data unless product.subscription?

        data.merge!(line_items: [{ quantity: 1, price: product.price_id }])
      end

      def checkout_success_data(product, session)
        if product.subscription?
          { type: 'complete', sessionId: session.id }
        else
          {
            type: 'setup',
            sessionId: session.id,
            setupIntent: session.setup_intent
          }
        end
      end
    end
  end
end
