module Drn
  module Mentoring
    module MainHelpers
      def mentor_availability(product, user)
        return nil unless product.policy.respond_to?(:mentor_availability)

        times = product.policy.mentor_availability
        not_available = product.disabled?(user)

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
    end
  end
end
