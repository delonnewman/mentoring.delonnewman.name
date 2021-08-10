require_relative '../lib/drn/framework'

SimpleApp = Drn::Framework::Application.init(:development) do |app|
  class Address < app.Entity
    has :number
    has :street
    has :city
    has :state
  end

  class Contact < app.Entity
    has :first_name
    has :last_name
    has :title
    has :suffix
    has :address, Address

    def name
      "#{first_name} #{last_name}"
    end
  end
end
