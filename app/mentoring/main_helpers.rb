# frozen_string_literal: true

module Mentoring
  # Helpers for Main controller
  module MainHelpers
    def mentor_availability_schedule(mentor)
      rows = mentor.availability_schedule.map do |(wday, range)|
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

    def mentor_availability_status(mentor)
      return mentor_available if mentor.available?
    end

    def mentor_available
      <<~HTML
        <span class="mr-1" style="font-size:0.8em; color: green">
          <i class="fas fa-circle"></i>
        </span>
        Available
      HTML
    end

    def fmt_hour(hour)
      if hour == 12
        '12:00 PM'
      elsif hour.zero? || hour == 24
        '12:00 AM'
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

      if !subscriber
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

      <<~HTML
        <button
          id="btn-#{product.id}"
          class="btn btn-primary btn-select-product #{btn_class}" #{disabled}
        >
          Select
        </button>
      HTML
    end

    def session_name(session, current_user)
      "Session with #{display_user other_user(current_user, session.mentor, session.customer)}"
    end

    def display_user(user, current_user = nil)
      return 'You' if user.id == current_user&.id

      user.first_name
    end

    def other_user(current_user, user1, user2)
      return user2 if current_user.id == user1.id

      user1
    end
  end
end
