# frozen_string_literal: true

require 'el/time_utils'

module Mentoring
  module Sessions
    # Routes for mentoring sessions
    class Router < Application.Router()
      namespace '/session' do
        # session management
        get    '/new', SessionsController, :new, as: :new_session
        post   '/',    SessionsController, :create
        get    '/:id', SessionsController, :show
        post   '/:id', SessionsController, :update
        delete '/:id', SessionsController, :end

        # billing
        post '/:id/bill',   BillingController, :bill_session, as: :bill_session
        post '/:id/amount', BillingController, :session_cost, as: :session_cost
      end
    end
  end
end
