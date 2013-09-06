require 'cuca/stdlib/form'
require 'cuca/stdlib/formerrors'
require 'cuca/stdlib/formelements'
require 'cuca/generator/markaby'

# == Form's for ActiveRecord
# AR Form build a form by providing one model of ActiveRecord.
# Likly that you want to overwrite the form method to
# run a custom layout.
#
# This Widget will call <form_name>_submit(model) if Form is submitted
# and validation of the model is passed. You still have to save the model.
#
# = Example:
#
#  ARForm('user_edit', User.find_by_username('bones'), 
#                     :disable_on_update => ['username', 'created'])
#


class ARFormWidget < FormWidget

 include Cuca::Generator::Markaby
 include Cuca::FormElements

 # valid options
 # * :disabled_on_create => ['field_name_1', 'field_name_2', ..]
 #     switch off fields on new records
 # * :diabled_on_update =>  ['field_name_1', 'field_name_2', ..]
 #     switch off fields on existing records
 # * :save_attribs => ['attr1', 'attr2']
 #     allow to call a setter even if it's not a db column
 # * .. options from FormWidgets ...
 def output(form_name, model, options = {})
   @model = model
   @disabled_on_update = options[:disabled_on_update] || []
   @disabled_on_create = options[:disabled_on_create] || []
   @hidden_on_update     = options[:hidden_on_update] || []
   @hidden_on_create     = options[:hidden_on_create] || []
   @save_attribs         = options[:save_attribs]     || []


   setup if self.respond_to?(:setup)		# you might want to use a method for setup


   options[:default_values] = model.attributes.merge(options[:default_values] || {})
   @save_attribs.each do |sa|
      options[:default_values][sa] = model.send(sa.intern) if model.respond_to?(sa.intern)
   end

   super(form_name, options)
 end


 # On submit will pass the model to the callback on the controller
 def on_submit
  controller.send(@form_name+'_submit', @model) unless controller.nil?
  clear
 end


 
 #
 # Validate will check on ActiveRecord validation errors
 #
 def validate(variables)
   form	if @_content.empty? # password fields might write hints to the validator...
   clear
   @form_errors = {}
   p = variables
   p.delete(@submit_name)
   
   if @model.new_record? then 
      @disabled_on_create.each { |d| p.delete(d) }
      @hidden_on_create.each { |d| p.delete(d) }
   else 
      @disabled_on_update.each { |d| p.delete(d) }
      @hidden_on_update.each { |d| p.delete(d) }
   end

   # don't save empty passwords!!
   @password_fields ||= []
   @password_fields.each do |pwf|
      p.delete(pwf) if p[pwf].chomp.empty?
   end

   # remove possible additional data that model doesn't support to
#   p.delete_if { |k,v| !@mode.respond_to?("#{k}=") }

   column_names = @model.class.columns.map { |c| c.name }
   p.each do |k,v|
     @model.send("#{k}=".intern, v) if (column_names.include?(k) && @model.respond_to?("#{k}=")) || @save_attribs.include?(k)
   end
   # @model.attributes = p
   
   return true if @model.valid?

   @model.errors.each do |k,v|
      @form_errors[k] = v
   end
 end
 
 
 
  def field_enable?(fname)
   if @model.new_record? then
      return @disabled_on_create.include?(fname) ? false : true
   else
      return @disabled_on_update.include?(fname) ? false : true
   end
 end
 
 def field_hidden?(fname)
   if @model.new_record? then
      return @hidden_on_create.include?(fname) ? true : false
   else
      return @hidden_on_update.include?(fname) ? true : false
   end
 end
 
 
 
 def fe(type, name)
   return '' if field_hidden?(name)
   attribs = {}
   attribs[:disabled] = '' unless field_enable?(name)
   r = ""
   case(type)
       when :string
          r << fe_text(name, attribs)
       when :boolean
          r << fe_bool(name, attribs)
       when :integer
         r << fe_int(name, attribs)
       when :datetime
         r << fe_datetime(name, attribs)
       when :date
         r << fe_date(name, attribs)
       when :password
         r << fe_password(name, attribs)
     end
   return r
 end
 
  # build a form element for column name
 def fe_for(column_name)
   col = @model.column_for_attribute(column_name)
   fe(col.type, col.name)
 end

  # you might want to replace this method
 public
 def form
   mab do
      FormErrors(@form_errors)
      fe_formstart
      table do
         @model.class.columns.each do |col|
            next if field_hidden?(col.name)
            tr { td { col.name }; td { fe(col.type, col.name) } }
         end
         tr { td {} ; td { fe_submit }}
      end
      fe_formend
   end
 end
end

