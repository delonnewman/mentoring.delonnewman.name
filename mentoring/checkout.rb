# frozen_string_literal: true

module Mentoring
  # Routes for product checkout
  class Checkout < El::Router
    get '/setup' do
      settings = { pub_key: app.settings['STRIPE_PUB_KEY'] }

      settings[:prices] = app.products.map do |product|
        {
          product_id: product.id,
          price_id: product.price_id,
          name: product.name
        }
      end

      render json: settings
    end

    post '/session' do
      data = JSON.parse(request.body.read, symbolize_names: true)
      product = app.products.find_by!(id: data[:product_id])

      logger.info "From Product ID: #{data[:product_id].inspect}"
      logger.info "Creating session with #{product.inspect}"

      # See https://stripe.com/docs/api/checkout/sessions/create
      # for additional parameters to pass.
      # {CHECKOUT_SESSION_ID} is a string literal; do not change it!
      # the actual Session ID is returned in the query parameter when your customer
      # is redirected to the success page.
      begin
        session = app.billing.create_checkout_session!(current_user, product)
        logger.info "Session created: #{session.inspect}"

        render json: app.billing.checkout_success_data(product, session)
      rescue StandardError => e
        logger.error e
        render json: { status: 'error', message: e.message }, status: 400
      end
    end

    post '/customer-portal' do
      data = JSON.parse(request.body.read)

      # For demonstration purposes, we're using the Checkout session to retrieve the customer ID.
      # Typically this is stored alongside the authenticated user in your database.
      checkout_session = Stripe::Checkout::Session.retrieve(data['sessionId'])

      # This is the URL to which users will be redirected after they are done
      # managing their billing.
      return_url = app.settings['DOMAIN']

      session = Stripe::BillingPortal::Session.create(
        customer: checkout_session['customer'],
        return_url: return_url
      )

      render json: { url: session.url }
    end

    post '/webhook' do
      # You can use webhooks to receive information about asynchronous payment events.
      # For more about our webhook events check out https://stripe.com/docs/webhooks.
      webhook_secret = app.settings['STRIPE_WEBHOOK_SECRET']
      payload = request.body.read

      if !webhook_secret.empty?
        # Retrieve the event by verifying the signature using the raw body and
        # secret if webhook signing is configured.
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']
        event = nil

        begin
          event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
        rescue JSON::ParserError => e
          # Invalid payload
          logger.error e.message
          return { status: 400 }
        rescue Stripe::SignatureVerificationError => e
          # Invalid signature
          logger.error e.message
          return { status: 400 }
        end
      else
        data = JSON.parse(payload, symbolize_names: true)
        event = Stripe::Event.construct_from(data)
      end

      if event['type'] == 'checkout.session.completed'
        render json: { status: 'success' }
      else
        render json: { status: 'error', data: event }
      end
    end
  end
end
