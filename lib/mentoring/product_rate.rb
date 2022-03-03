# frozen_string_literal: true

module Mentoring
  class ProductRate < El::Entity
    primary_key :id
    reference :name, String

    has :unit, String
    has :description, String, required: false
    has :subscription, :boolean, default: false

    alias to_s name
  end
end
