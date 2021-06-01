module Drn
  module Mentoring
    class AccountMessenger < Mailer
      layout :mailer
      
      def signup(user)
        mail :signup, { user: user }, to: user, subject: 'Thank you for giving us a try! Please complete your registration.'
      end

      private

        def activation_url(user)
          "#{app.settings['DOMAIN']}/activate/#{user.id}?key=#{user.activation_key}"
        end
    end
  end
end
