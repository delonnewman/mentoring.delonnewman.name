module Mentoring
  module Sessions
    class BillingController < El::Controller
      def bill_session
        session = app.sessions
                     .find_by!(id: params[:id])
                     .merge(cost: Float(params.dig(:session, :amount))) # TODO: improve entity coersion

        app.billing.bill_session!(session)

        redirect_to app.routes.session_path(session)
      end
    end

    def session_cost
      session = app.sessions.find_by(id: params[:id])
      duration = minutes(Float(params[:duration]))

      if session.nil?
        json.error("Invalid product #{params[:product_id].inspect}")
      else
        json.success(amount: session.merge(duration: duration).cost.magnitude.to_f.round(2))
      end
    end
  end
end
