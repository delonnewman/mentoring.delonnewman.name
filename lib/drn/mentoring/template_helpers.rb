module Drn
  module Mentoring
    module TemplateHelpers
      extend Trait
      required :app
      
      def url_for(path)
        "#{app.url_scheme}://#{File.join(app.settings['DOMAIN'], path)}"
      end

      def link_to(path, name, title: name, **options)
        classes = options[:class]
        classes = classes.join(' ') if classes.is_a?(Enumerable)

        %{<a href="#{url_for(path)}" title="#{title}" class="#{classes}">#{h name}</a>}
      end

      def input_field(name, value = params[name.to_s], type: 'text')
        if (errors = view.dig(:errors, name.to_sym))
          %{<input type="#{type}" class="form-control is-invalid" id="#{name}" name="#{name}" value="#{value}">
            <div class="invalid-feedback">#{errors.join(', ')}</div>}
        else
          %{<input type="#{type}" class="form-control" id="#{name}" name="#{name}" value="#{value}">}
        end
      end
      alias text_field input_field
      
      def datetime_field(name, value = params[name.to_s])
        input_field name, value, type: 'datetime-local'
      end

      def password_field(name, value = params[name.to_s])
        input_field name, value, type: 'password'
      end

      def email_field(name, value = params[name.to_s])
        input_field name, value, type: 'email'
      end

      def select_field(name, options, selected: nil)
        opts = case options
               when Hash
                 options.map do |k, v|
                   if v == selected
                     %{<option selected value="#{k}">#{h v}</option>}
                   else
                     %{<option value="#{k}">#{h v}</option>}
                   end
                 end
               else
                 options.map do |v|
                   if v == selected
                     %{<option selected>#{h v}</option>}
                   else
                     %{<option>#{h v}</option>}
                   end
                 end
               end

        select = %{<select name="#{name}">#{opts.join('')}</select>}
        if (errors = view.dig(:errors, name.to_sym))
          %{#{select}<div class="invalid-feedback">#{errors.join(', ')}</div>}
        else
          select
        end
      end

      def radio_buttons(name, options, selected: nil, inline: true)
        radios = options.each_with_index.map do |(id, text), i|
          %{<div class="form-check #{inline ? 'form-check-inline' : ''}">
               <input class="form-check-input" #{selected == id ? 'checked' : ''}
                      type="radio" name="#{name}" id="#{name}#{i}" value="#{id}">
               <label class="form-check-label" for="#{name}#{i}">#{text}</label>
            </div>}
        end

        radios.join('')
      end

      def entity_field(name, entity_class, **options)
        opts = entity_class.repository.map { |e| [e.id, e.to_s] }.to_h
        if opts.length < 5
          radio_buttons(name, opts, **options)
        else
          select_field(name, opts, **options)
        end
      end

      def form_field(attr, entity = nil)
        if attr.password?
          password_field attr.name
        elsif attr.time?
	  datetime_field attr.name, entity&.send(attr.name)
        elsif attr.email?
          email_field attr.name, entity&.send(attr.name)
        elsif attr.entity?
          entity_field attr.name, attr[:type], selected: entity&.send(attr.name)&.id
        else
          text_field attr.name, entity&.send(attr.name)
        end
      end
    end
  end
end
