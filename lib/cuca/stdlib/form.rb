# == FormWidget
#
# The FormWidget helps you to build and validate html forms.
#
# Every form has a name and some optional options per instance.
#
# = Implementation
#
# To implement your form, derive a class from FormWidget and implement these methods:
#
#  * form - To generate your form
#    - Use @form_name to name your form
#    - Use @submit_name to name your submit button
#  * validate(variables) - OPTIONAL
#    - Validate the result of the form (variables == hash with values)
#    - Write @form_errors['element_name'] = 'Error message' on all errors
#  * setup - OPTIONAL (setup additional stuff after object initialization)
#  * before_validate(variables)
#    - rewrite fields or compose real fields out of virtual fields
#  * on_submit - OPTIONAL
#    - Do stuff once submitted
#    - By default this method will call formname_submit on the controller
#
# = Usage
# 
# On a controller, call with
#
# MyForm('form_name', :option=>:value ..)
#
#
# = Example
#
#  class EmailFormWidget < ARFormWidget
#     include Cuca::FormElements
#     
#     # euser and edomain will complse email_address
#     def before_validate(variables)
#         variables['email_address'] = variables['euser'] + '@' + variables['edomain']
#         variables.delete('euser')
#         variables.delete('edomain')
#         variables
#     end
#    
#     def validate(var)
#        @form_errors['euser'] = 'Invalid Format' \
#                   unless var['email_address'] =~ /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,6}$/
#     end
#
#     # create a custom layout using FormElement module
#     def form
#       mab do
#          FormErrors(@form_errors)
#          fe_formstart
#          text "Email Address" ; fe_text('euser'); text '@' ; fe_text('edomain')
#          fe_submit
#          fe_formend
#       end
#     end
#  end
#
# On the controller
#
#  class EmailAddController < ApplicationController
#
#  def email_add_submit(var)
#      mab { text "You entered #{var.inspect}" }
#  end
#
#  def run
#    mab { EmailForm('email_add', :default_values => { :euser => 'your-name', :edomain => 'domain.com' } }
#  end
# end
#
class FormWidget < Cuca::Widget

 # Returns true if this form was posted
 def posted?
   return (request_method == 'POST' && !params[@submit_name].nil?)
 end

 # Returns true if a form with that name was posted
 def self.posted?(form_name)
   w = Cuca::Widget.new
   return (w.request_method == 'POST' && !w.params['submit_' + form_name].nil?)
 end
 
 # get form params and return them as hash. If form hasn't been posted yet
 # it will get the variables from the options[:default_values]
 def get_form_variables
   var = @options[:default_values] || {}
   params.each_pair { |k,v| var[k.to_s] = v } if posted? # request_method == 'POST'
   @variables = {}
   var.each_pair { |k,v| @variables[k.to_s] = v }		# this allows is to pass symbols to default_values
   @variables
 end
 
 # returns the default value for a variable.
 def get_default_variable(var)
   @options[:default_values].each_pair { |k,v| return v if k.to_s == var.to_s }
   nil   
 end

 # accessor to current values of a variable by name. This is for posted an un-posted forms.
 def v
  @variables
 end

 # Overwrite this method to setup initial values
 # This method will not be called if the form get submitted.
 def setup
 end

 # Create your form by overwriting this
 # Name your submit button @submit_name, so the form can detect if it
 # is submitted or not. You can use FormElements module to get access to some
 # helper functions to build really fast forms.
 def form
 end
 
 # this will get called with the request_parameters as arguments for you to filter. 
 # You can use this to create new fields and to get rid of virtual ones.
 def before_validate(variables)
  variables 
 end
 
 
 
 # Overwrite this method with your validation code.
 # Fill up @form_errors hash with error messages.
 def validate(variables)
 end

 # If form is validated we call on_submit. Default behaviour is to call
 # {form_name}_submit(raw_result, [rewritten_result]) on the CONTROLLER.
 def on_submit
  met = @form_name+"_submit"
  if controller.method(met.intern).arity == 2 then
    controller.send(met, @variables, @before_validate_variables) unless controller.nil?
  else
    controller.send(met, @variables) unless controller.nil?
  end
 end

 # options can be used for form specific stuff
 # we only use :post_to to set @post_to atm
 def output(form_name, options = {})
   @options = options
   @post_to   = @options[:post_to] || cgi.path_info
   @form_name = form_name
   @submit_name = 'submit_'+@form_name
   @form_errors = {}

   setup
   
   get_form_variables

   if posted? then
     @before_validate_variables = before_validate(request_parameters.dup)
     validate(@before_validate_variables)
     if @form_errors.empty? then
        return on_submit
     else
        form
     end
   else
     form
   end
 end
 
 def self.run(*args)
   w = self.class.new
   w.output(args)
 end
end
