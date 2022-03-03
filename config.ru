# frozen_string_literal: true

require_relative 'app/mentoring/application'

# And use Honeybadger's rack middleware
use Honeybadger::Rack::ErrorNotifier

# require 'rack-mini-profiler'
# use Rack::MiniProfiler

use Rack::Session::Cookie, secret: ENV['MENTORING_SESSION_SECRET']

run Mentoring::Application.init!
