# frozen_string_literal: true

module Mentoring
  class ProductRate < Application.Entity()
    primary_key :id
    reference :name, :string

    has :unit, :string
    has :description, :string, required: false
    has :subscription, :boolean, default: false

    alias to_s name
  end
end
