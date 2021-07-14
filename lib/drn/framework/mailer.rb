# frozen_string_literal: true
module Drn
  module Framework
    class Mailer < Templated
      include Invokable

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def logger
        app.logger
      end

      protected

      def mail(
        name,
        view = EMPTY_HASH,
        to:,
        from: 'contact@delonnewman.name',
        subject:
      )
        content = render_template(name, view)

        msg = [
          {
            'From' => {
              'Email' => from,
              'Name' => "Delon Newman's Email Bot"
            },
            'To' => [{ 'Email' => to.email, 'Name' => to.username }],
            'Subject' => subject,
            'HTMLPart' => content
          }
        ]

        logger.info "Sending message: #{msg.inspect}"

        Concurrent::Promises.future do
          res = Mailjet::Send.create(messages: msg)
          logger.info "Mailjet response: #{res.inspect}"
          res
        end
      end
    end
  end
end
