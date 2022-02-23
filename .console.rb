require_relative 'app/mentoring'

def app(env = :development)
  @apps ||= {}
  @apps[env] ||= Mentoring::Application.new(env)
end
