# coding: utf-8
# frozen_string_literal: true
module Drn
  module Mentoring
    class Main < Framework::Controller
      class Checkout < Framework::Controller
        include Framework::Authenticable

        get '/setup' do
          settings = { pub_key: Drn::Mentoring.app.settings['STRIPE_PUB_KEY'] }

          settings[:prices] =
            app.products.map do |product|
              {
                product_id: product.id,
                price_id: product.price_id,
                name: product.name
              }
            end

          render json: settings
        end

        # Fetch the Checkout Session to display the JSON result on the success page
        # TODO: Remove
        get '/session/:session_id' do |params|
          logger.info "Checkout Session params: #{params.inspect}"

          render json: Stripe::Checkout::Session.retrieve(params[:session_id])
        end

        post '/session' do |params, request|
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
            logger.info "#{self}"

            # TODO: Take customer id from session and add to user account & associate product with customer
            session = Stripe::Checkout::Session.create(session_data(product))
            logger.info "Session created: #{session.inspect}"
            render json: success_data(product, session)
          rescue => e
            logger.error e
            render json: { status: 'error', message: e.message }, status: 400
          end
        end

        post '/customer-portal' do |params, request|
          data = JSON.parse(request.body.read)

          # For demonstration purposes, we're using the Checkout session to retrieve the customer ID.
          # Typically this is stored alongside the authenticated user in your database.
          checkout_session_id = data['sessionId']
          checkout_session =
            Stripe::Checkout::Session.retrieve(checkout_session_id)

          # This is the URL to which users will be redirected after they are done
          # managing their billing.
          return_url = Drn::Mentoring.app.settings['DOMAIN']

          session =
            Stripe::BillingPortal::Session.create(
              { customer: checkout_session['customer'], return_url: return_url }
            )

          render json: { url: session.url }
        end

        post '/webhook' do |params, request|
          # You can use webhooks to receive information about asynchronous payment events.
          # For more about our webhook events check out https://stripe.com/docs/webhooks.
          webhook_secret = Drn::Mentoring.app.settings['STRIPE_WEBHOOK_SECRET']
          payload = request.body.read
          if !webhook_secret.empty?
            # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
            sig_header = request.env['HTTP_STRIPE_SIGNATURE']
            event = nil

            begin
              event =
                Stripe::Webhook.construct_event(
                  payload,
                  sig_header,
                  webhook_secret
                )
            rescue JSON::ParserError => e
              # Invalid payload
              return { status: 400 }
            rescue Stripe::SignatureVerificationError => e
              # Invalid signature
              puts '⚠️  Webhook signature verification failed.'
              return { status: 400 }
            end
          else
            data = JSON.parse(payload, symbolize_names: true)
            event = Stripe::Event.construct_from(data)
          end

          # Get the type of webhook event sent - used to check the status of PaymentIntents.
          event_type = event['type']
          data = event['data']
          data_object = data['object']

          if event_type == 'checkout.session.completed'
            puts '🔔  Payment succeeded!'
          end

          render json: { status: 'success' }
        end

        # Helpers
        def success_url(product)
          if product.subscription?
            "http://#{Drn::Mentoring.app.settings['DOMAIN']}?session_id={CHECKOUT_SESSION_ID}"
          else
            "http://#{Drn::Mentoring.app.settings['DOMAIN']}/session/new?session_id={CHECKOUT_SESSION_ID}"
          end
        end

        def session_data(product)
          data = {
            success_url: success_url(product),
            cancel_url: "http://#{Drn::Mentoring.app.settings['DOMAIN']}",
            payment_method_types: ['card'],
            mode: product.checkout_mode
          }

          if not product.subscription?
            data
          else
            data.merge!(line_items: [{ quantity: 1, price: product.price_id }])
          end
        end

        def success_data(product, session)
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
end
