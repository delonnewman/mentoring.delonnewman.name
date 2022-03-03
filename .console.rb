require_relative 'mentoring/application'

def app(env = :development)
  @apps ||= {}
  @apps[env] ||= Mentoring::Application.new(env)
end
