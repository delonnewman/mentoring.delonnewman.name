# frozen_string_literal: true

module Drn
  module Mentoring
    # Manage email communication regarding accounts
    class AccountMessenger < Mailer
      layout :mailer

      def signup(user)
        mail :signup, { user: user },
             to:      user,
             subject: 'Thank you for giving us a try! Please complete your registration.'
      end

      private

      def activation_url(user)
        "https://#{app.settings['DOMAIN']}/activate/#{user.id}?key=#{user.activation_key}"
      end
    end
  end
end
