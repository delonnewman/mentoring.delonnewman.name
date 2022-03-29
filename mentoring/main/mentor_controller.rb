# frozen_string_literal: true

module Mentoring
  module Main
    class MentorController < ApplicationController
      def index
        render Main::MentorView
      end

      def state
        state = { authenticated: authenticated? }

        render js: "Mentoring = {}; Mentoring.state = #{state.to_json}"
      end
    end
  end
end
