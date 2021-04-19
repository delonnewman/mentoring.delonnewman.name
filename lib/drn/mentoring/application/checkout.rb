module Drn
  module Mentoring
    class Application
      class Checkout
        include Rack::Routable

        static '/' => M.root.join('public')

        post '/create-checkout-session' do
          content_type 'application/json'
          data = JSON.parse(request.body.read)
        
          # See https://stripe.com/docs/api/checkout/sessions/create
          # for additional parameters to pass.
          # {CHECKOUT_SESSION_ID} is a string literal; do not change it!
          # the actual Session ID is returned in the query parameter when your customer
          # is redirected to the success page.
          begin
            session = Stripe::Checkout::Session.create(
              success_url: 'http://localhost/success.html?session_id={CHECKOUT_SESSION_ID}',
              cancel_url: 'http://localhost/canceled.html',
              payment_method_types: ['card'],
              mode: 'subscription',
              line_items: [{
                # For metered billing, do not pass quantity
                quantity: 1,
                price: data['priceId'],
              }],
            )
          rescue => e
            halt 400,
              { 'Content-Type' => 'application/json' },
              { 'error': { message: e.error.message } }.to_json
          end
        
          { sessionId: session.id }.to_json
        end
      end
    end
  end
end
