module Mentoring
  module Sessions
    class BillingController < ApplicationController
      def bill_session
        session = app.sessions.find_by!(id: params[:id])
        session.merge!(cost: params.dig(:session, :amount).to_f) # TODO: improve entity coersion

        app.billing.bill_session!(session)

        redirect_to routes.session_path(session)
      end
    end

    def session_cost
      session = app.sessions.find_by!(id: params[:id])
      duration = params[:duration].to_f.minutes

      json.success(amount: session.merge(duration: duration).cost.to_f)
    end
  end
end
