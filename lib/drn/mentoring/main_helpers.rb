# frozen_string_literal: true

module Drn
  module Mentoring
    # Helpers for Main controller
    module MainHelpers
      def mentor_availability(mentor)
        rows = mentor.meta['profile.availability'].map do |(wday, range)|
          "<tr><th>#{Date::DAYNAMES[wday]}</th><td>#{fmt_hour range[:start]} &mdash; #{fmt_hour range[:end]}</td></tr>"
        end

        <<~HTML
          <style>
            @media (min-width:960px) {
              .table-availability {
                 width: 300px;
              }
            }

            .table-availability td {
               white-space: nowrap;
            }
          </style>
          <table class="table table-sm table-borderless table-availability text-right">
            #{rows.join('')}
          </table>
        HTML
      end

      def fmt_hour(hour)
        if hour == 12
          "12:00 PM"
        elsif hour == 0 || hour == 24
          "12:00 AM"
        elsif hour < 12
          "#{hour}:00 AM"
        else
          "#{hour - 12}:00 PM"
        end
      end

      def subscriber?(products)
        products.any? do |(product, purchased)|
          product.subscription? && purchased
        end
      end

      def product_price(product, subscriber: false, size: nil)
        return '<div></div>' if app.env == :production

        discount = subscriber ? product.price / 2 : product.price
        product_size = size.nil? ? '1.3em' : '0.9em'
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
