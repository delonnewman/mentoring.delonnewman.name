require 'spec_helper'

class ZoomClient
  def meeting_create(user_id:, topic:)
    puts "Create meeting for user #{user_id.inspect} with topic #{topic.inspect}"
  end
end

class App
  def zoom_client
    ZoomClient.new
  end
end

class Mentor
  def email
    "mentor@example.com"
  end

  def first_name
    "Mentor"
  end
end

class Customer
  def first_name
    "Customer"
  end
end

class Session
  def id
    1
  end

  def mentor
    Mentor.new
  end

  def customer
    Customer.new
  end
end

RSpec.describe Drn::Mentoring::ZoomMeeting do
  describe '.start!' do
    it 'creates a new meeting for the mentoring session or returns a meeting if one has already be created for that session' do
      app = App.new
      session0 = Session.new
      session1 = Session.new
      meeting0 = ZoomMeeting.start!(app, session0)
      meeting1 = ZoomMeeting.start!(app, session1)

      expect(meeting0).to be meeting1
    end
  end
end
