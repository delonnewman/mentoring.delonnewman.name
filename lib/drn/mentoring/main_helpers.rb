# frozen_string_literal: true

module Drn
  module Mentoring
    # Helpers for Main controller
    module MainHelpers
      def mentor_availability(product, user)
        return nil unless product.policy.respond_to?(:mentor_availability)

        times = product.policy.mentor_availability
        not_available = app.env == :production || product.disabled?(user)

        data =
          times.map do |wday, t|
            day = Date::DAYNAMES[wday]
            t.merge(day: day)
          end

        class_name = not_available ? 'mentor-availability' : 'mentor-available'
        title = not_available ? 'Your mentor is available on:' : 'Your mentor is available'

        <<~HTML
          <div style="font-size: 0.9em" class="mt-3 text-muted">
            <strong>#{title}</strong>
            <input
             type="hidden"
             class="#{class_name}"
             id="mentor-availability-#{product.id}"
             value="#{h data.to_json}"
            >
          </div>
        HTML
      end

      def subscriber?(products)
        products.any? do |(product, purchased)|
          product.subscription? && purchased
        end
      end

      def product_price(product, subscriber: false, size: nil)
        return '<div></div>' if app.env == :production

        discount = subscriber ? product.price / 2 : product.price
        product_size = size.nil? ? '1.5em' : '1.1em'
        desc_size = size.nil? ? '1.1em' : '0.9em'

        if not subscriber
          <<~HTML
            <div class="price">
              <span class="font-weight-bold" style="font-size:#{product_size}">#{money product.price}</span>
              <span style="font-size:#{desc_size}" class="text-muted">#{product.rate.description}</span>
            </div>
          HTML
        else
          <<~HTML
            <div class="price">
              <span class="font-weight-bold" style="font-size:#{product_size}">
                <s class="text-muted" style="font-size:0.8em">#{money product.price}</s>
                #{money discount}
              </span>
              <span style="font-size:#{desc_size}" class="text-muted">#{product.rate.description}</span>
            </div>
          HTML
        end
      end

      def product_button(product, size: nil)
        disabled = 'disabled' if app.env == :production || product.disabled?(current_user)
        btn_class = size.nil? ? nil : "btn-#{size}"

        %{ <button id="btn-#{product.id}" class="btn btn-primary btn-select-product #{btn_class}" #{disabled}>Select</button> }
      end
    end
  end
end
