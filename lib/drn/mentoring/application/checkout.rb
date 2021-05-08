# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Checkout < Controller
        get '/setup' do
          settings = { pub_key: ENV.fetch('STRIPE_PUB_KEY') }

          settings[:prices] = products.map do |product|
            product.to_h.slice(:price_id, :name, :subscription)
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
          data = JSON.parse(request.body.read)
          product = products.by_price_id!(data['priceId'])

          logger.info "From Price ID: #{data['priceId'].inspect}"
          logger.info "Creating session with #{product.inspect}"

          # See https://stripe.com/docs/api/checkout/sessions/create
          # for additional parameters to pass.
          # {CHECKOUT_SESSION_ID} is a string literal; do not change it!
          # the actual Session ID is returned in the query parameter when your customer
          # is redirected to the success page.
          begin
            session = Stripe::Checkout::Session.create(session_data(product))
            logger.info "Session created: #{session.inspect}"
            render json: success_data(product, session)
          rescue => e
            logger.error e
            render json: { error: { message: e.message } }, status: 400
          end
        end

        post '/customer-portal' do |params, request|
          data = JSON.parse(request.body.read)
        
          # For demonstration purposes, we're using the Checkout session to retrieve the customer ID.
          # Typically this is stored alongside the authenticated user in your database.
          checkout_session_id = data['sessionId']
          checkout_session = Stripe::Checkout::Session.retrieve(checkout_session_id)
        
          # This is the URL to which users will be redirected after they are done
          # managing their billing.
          return_url = ENV['DOMAIN']
        
          session = Stripe::BillingPortal::Session.create({
            customer: checkout_session['customer'],
            return_url: return_url
          })
        
          render json: { url: session.url }
        end
        
        post '/webhook' do |params, request|
          # You can use webhooks to receive information about asynchronous payment events.
          # For more about our webhook events check out https://stripe.com/docs/webhooks.
          webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
          payload = request.body.read
          if !webhook_secret.empty?
            # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
            sig_header = request.env['HTTP_STRIPE_SIGNATURE']
            event = nil
        
            begin
              event = Stripe::Webhook.construct_event(
                payload, sig_header, webhook_secret
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
        
          puts '🔔  Payment succeeded!' if event_type == 'checkout.session.completed'
        
          render json: { status: 'success' }
        end
      end
    end
  end
end
