# frozen_string_literal: true

module Mentoring
  # Represent a Zoom meeting interactions with the API and retrieving it's data
  class ZoomMeeting
    def self.create!(client, customer, mentor, start_at: Time.now)
      new(client, customer, mentor).create!(start_at)
    end

    def self.from_session(client, session)
      new(client, session.customer, session.mentor, session.zoom_meeting_id)
    end

    attr_reader :client, :customer, :mentor

    def initialize(client, customer, mentor, id = nil)
      @client = client
      @customer = customer
      @mentor = mentor
      @id = id
    end

    def fetch_data!
      @data ||=
        begin
          raise 'An id is required to fetch data' unless @id

          @client.meeting_get(meeting_id: @id)
        end

      self
    end

    def create!(start_time = Time.now)
      @data ||= @client.meeting_create(user_id: @mentor.email, topic: topic, start_time: start_time)

      self
    end

    def delete!
      @client.meeting_delete(meeting_id: id)

      self
    end

    def topic
      "Mentoring Session with #{@mentor.first_name} & #{@customer.first_name}"
    end

    def id
      @id || self['id']
    end

    def join_url
      self['join_url']
    end

    def start_url
      self['start_url']
    end

    def [](key)
      @data && @data[key]
    end
  end
end
