module El
  # A view that represents an entire page so will include a layout
  class PageView < View
    def render
      render_layout { super }
    end

    private

    def render_layout
      eval(Templates.new(self).layout_template(controller.layout).code)
    end
  end
end
