module Mentoring
  module Sessions
    class BillingController < ApplicationController
      def bill_session
        session = app.sessions
                     .find_by!(id: params[:id])
                     .merge(cost: Float(params.dig(:session, :amount))) # TODO: improve entity coersion

        app.billing.bill_session!(session)

        redirect_to routes.session_path(session)
      end
    end

    def session_cost
      session = app.sessions.find_by(id: params[:id])
      duration = minutes(Float(params[:duration]))

      if session.nil?
        json.error("Invalid product #{params[:product_id].inspect}")
      else
        json.success(amount: session.merge(duration: duration).cost.to_f)
      end
    end
  end
end
