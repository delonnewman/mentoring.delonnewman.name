module Drn
  module Mentoring
    module TemplateHelpers
      def text_field(name, value = params[name.to_s])
        if (errors = view.dig(:errors, name.to_sym))
          %{<input type="text" class="form-control is-invalid" id="#{name}" name="#{name}" value="#{value}">
            <div class="invalid-feedback">#{errors.join(', ')}</div>}
        else
          %{<input type="text" class="form-control" id="#{name}" name="#{name}" value="#{value}">}
        end
      end

      def password_field(name, value = params[name.to_s])
        if (errors = view.dig(:errors, name.to_sym))
          %{<input type="password" class="form-control is-invalid" id="#{name}" name="#{name}" value="#{value}">
            <div class="invalid-feedback">#{errors.join(', ')}</div>}
        else
          %{<input type="password" class="form-control" id="#{name}" name="#{name}" value="#{value}">}
        end
      end
    end
  end
end
