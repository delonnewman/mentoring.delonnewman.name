# frozen_string_literal: true
module Drn
  module Mentoring
    class Application
      class Checkout < Controller
        static '/' => App.root.join('public')

        get '/' do
          render :index
        end

        get '/setup' do
          render json: {
            publishableKey: ENV['STRIPE_PUB_KEY'],
            basicPrice: ENV['BASIC_PRICE_ID'],
            proPrice: ENV['PRO_PRICE_ID']
          }
        end

        # Fetch the Checkout Session to display the JSON result on the success page
        get '/checkout-session' do |params|
          #content_type 'application/json'
          session_id = params[:sessionId]
        
          session = Stripe::Checkout::Session.retrieve(session_id)
          render json: session
        end

        post '/create-checkout-session' do |params, request|
          data = JSON.parse(request.body.read)
        
          # See https://stripe.com/docs/api/checkout/sessions/create
          # for additional parameters to pass.
          # {CHECKOUT_SESSION_ID} is a string literal; do not change it!
          # the actual Session ID is returned in the query parameter when your customer
          # is redirected to the success page.
          begin
            session = Stripe::Checkout::Session.create(
              success_url: 'http://localhost:9393/success.html?session_id={CHECKOUT_SESSION_ID}',
              cancel_url: 'http://localhost:9393/canceled.html',
              payment_method_types: ['card'],
              mode: 'subscription',
              line_items: [{
                # For metered billing, do not pass quantity
                quantity: 1,
                price: data['priceId'],
              }],
            )
        
            render json: { sessionId: session.id }
          rescue => e
            { status: 400,
              headers: { 'Content-Type' => 'application/json' },
              body: StringIO.new({ 'error': { message: e.error.message } }.to_json) }
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
        
        post '/webhook' do
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
