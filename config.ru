# frozen_string_literal: true

require_relative 'lib/drn/mentoring'

# And use Honeybadger's rack middleware
use Honeybadger::Rack::ErrorNotifier

require 'rack-mini-profiler'
use Rack::MiniProfiler

run Drn::Mentoring.app
