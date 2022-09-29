# frozen_string_literal: true

module El
  class Messenging < Advice
    advises Application, as: :app, delegating: %i[logger]
    advised_by Templates, delegating: %i[render_template]

    include Templating
    include Invokable

    def deliver!(message, *args)
      public_send(message, *args).wait!
    end

    DEFAULT_FROM = 'contact@delonnewman.name'

    def mail(name, view = EMPTY_HASH, to:, subject:, from: DEFAULT_FROM)
      content = render_template(name, view)

      msg = [{
        'From' => {
          'Email' => from,
          'Name' => 'Delon R. Newman Mentoring Bot'
        },
        'To' => [{ 'Email' => to.email, 'Name' => to.username }],
        'Subject' => subject,
        'HTMLPart' => content
      }]

      logger.info "Sending message: #{msg.inspect}"

      Concurrent::Promises.future do
        res = Mailjet::Send.create(messages: msg)
        logger.info "Mailjet response: #{res.inspect}"
        res
      end
    end
  end
end
