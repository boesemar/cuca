require 'cuca/generator/markaby'

# this widget you can use within a form to display all form errors
class FormErrorsWidget < Cuca::Widget
 
 include Cuca::Generator::Markaby
 
 def output(form_errors, title = nil)
   return if form_errors.empty?
   mab {
     b title ? title : "Form contains errors"
     ul {
      form_errors.each_pair { |name, value| 
         li { b {name}; text " - #{value}" }
      }
     }
   }
 end

end
