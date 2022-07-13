module El
  # An anonymous view based on hash data
  class HashView < View
    attr_reader :template_name

    def initialize(controller, name, data)
      super(controller)

      @template_name = name
      @__data__      = data

      data.each_pair do |key, value|
        define_singleton_method(key) { value }
      end
    end

    def to_h
      @__data__.dup
    end

    def to_json(*args)
      @__data__.to_json(*args)
    end

    def view
      @__data__
    end
  end
end
