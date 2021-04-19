module Drn
  module Mentoring
    module_function
  
    def env
      ENV.fetch('RACK_ENV') { :development }.to_sym
    end
  
    def logger
      @logger ||= Logger.new(STDOUT)
    end
  
    def root
      @root ||= Pathname.new(File.join(__dir__, '..', '..')).expand_path
    end
  
    def db
      @db ||= Sequel.connect(ENV.fetch('DATABASE_URL'))
    end
  end
end
