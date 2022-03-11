# frozen_string_literal: true

module Mentoring
  module Main
    class Controller < El::Controller
      def index
        products = app.products.products_with_states(user: current_user, mentors: app.users.mentors_not_in_sessions)

        logger.info "CONTENT_TYPE: #{request.content_type.inspect}"

        render :index, with: { products: products, mentor: app.users.default_mentor }
      end

      def state
        state = { authenticated: authenticated? }

        render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
      end

      def dashboard
        render :dashboard, with: DashboardView.new(app, current_user)
      end
    end
  end
end
