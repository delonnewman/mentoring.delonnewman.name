# frozen_string_literal: true

module Mentoring
  # A collection of functions for billing customers
  class Billing < Application.Service()
    start do
      Stripe.api_key = app.settings[:stripe_key]
    end

    def bill_session!(session)
      return unless session.checkout_session_id

      create_payment!(session)

      app.sessions.update!(session.id, session.merge(billed_at: Time.now))
    end

    def create_payment!(session)
      checkout = Stripe::Checkout::Session.retrieve(checkout_id)
      intent = Stripe::SetupIntent.retrieve(checkout.setup_intent)

      Stripe::PaymentIntent.create(
        amount: session.cost.in(:cents).to_i,
        currency: 'usd',
        payment_method_types: ['card'],
        customer: checkout.customer,
        payment_method: intent.payment_method
      )
    end

    def create_customer!(user)
      Stripe::Customer.create(name: user.name, email: user.email, description: user.stripe_description)
    end

    def find_or_create_customer!(user)
      if user.stripe_customer_id?
        Stripe::Customer.retrieve(user.stripe_customer_id)
      else
        create_customer!(user).tap do |customer|
          app.users.add_stripe_customer_id!(id: user.id, stripe_id: customer.id)
        end
      end
    end

    def create_checkout_session!(user, product)
      customer = find_or_create_customer!(user)

      Stripe::Checkout::Session.create(checkout_session_data(product, customer))
    end

    private

    def checkout_success_url(product)
      if product.subscription?
        "#{app.routes.products_subscribe_url(product.id)}?session_id={CHECKOUT_SESSION_ID}"
      else
        "#{app.routes.session_new_url(product_id: product.id)}&session_id={CHECKOUT_SESSION_ID}"
      end
    end

    def checkout_session_data(product, customer)
      data = {
        success_url: checkout_success_url(product),
        cancel_url: app.routes.root_url,
        payment_method_types: ['card'],
        mode: product.checkout_mode,
        customer: customer.id
      }

      return data unless product.subscription?

      data.merge!(line_items: [{ quantity: 1, price: product.price_id }])
    end
  end
end
