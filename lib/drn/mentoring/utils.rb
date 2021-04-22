module Drn
  module Mentoring
    module_function
  
    def env
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
