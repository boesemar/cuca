require 'erb'
require 'cuca/generator_context'

module Cuca
module Generator

# == View Generator
#
# The view generator allows you to define content using an ERB template - similar to 
# Ruby on Rails.
# 
# Example use within a Controller:
#
#  require 'cuca/generator/view'
#  class IndexController
#    include Cuca::Generator::View
#
#    def run
#      @some_variable = "Stuff"
#      @page_title = "Hello World"
#      view('template.rhtml')
#    end
#  end
#
# And the template (template.rhtml)
#
#  <html>
#   <head>
#    <title><%= @page_title %></title>
#   </head>
#   <body>
#     <% (1..10).each do |idx|  %>  <!-- Embedded Ruby Code ->
#       <%= idx.to_s %> - <b>Some variable: <%= @stuff %></b><br/>
#     <% end %>
#     An external Widget: <%= Link('/to/somewhere') { b { "Click me" }} %>
#   </body>
#  </html>
#
# For more information about ERB templates visit it's website.
#
module View

  # Produce content by a template file.
  # This will return the generated markup as a string
  def viewtext(filename=nil)
    view_dir = $cuca_path + '/' + App::config['view_directory']

    begin
       template = File.read(view_dir + "/#{filename}")
    rescue => e
       return "Error reading template: #{e}"
    end

    if RUBY_VERSION > '1.8' && Cuca::App.config['view_encoding'] then
      template.force_encoding(Cuca::App.config['view_encoding'])
    end
 
    viewtext_p(template)
  end


  # Procuce content and append to widget.
  def view(filename)
     @_content << viewtext(filename)  
  end
  
  # Normally you have your view (the template) within a separate file. Nevertheless
  # you can passing as a string to this function.
  def viewtext_p(template)
    ERB.new(template).result(GeneratorContext.new(get_assigns, self).get_bindings)
  end
  
  # Equivaltent to view but take template as a string.
  def view_p(template)
    @_content << viewtext_p(template)
  end

end

end # Mod: Generator
end # Mod: Cuca
