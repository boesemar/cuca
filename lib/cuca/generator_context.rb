# A good context for generators. It will find and run widgets on method_missing.
#
class GeneratorContext
   def get_bindings
       binding
   end

   def initialize(assigns, base_object)
      assigns.each_pair do |k,v|
         instance_variable_set("@#{k}", v)
      end
      @base = base_object
   end
        
   def method_missing(sym, *args, **kwargs, &block )
      class_name = sym.id2name

      # 1st try to find method in the base widget
      if @base.respond_to?(class_name.intern) then 
         return @base.send(class_name, *args, **kwargs, &block)
      end
      c = nil
      # 2nd try to find a widget
      if Object.const_defined?(class_name+'Widget') then
         c = Object::const_get(class_name+"Widget")
      else
         # try to find the widget in the action namespace
         return old_method_missing(sym, *args, **kwargs, &block) if $cuca.value[:app].nil?
         
         am = $cuca.value[:url_scan].action_module
         if am.const_defined?(class_name+'Widget') then
            c = am.const_get(class_name+'Widget')
         else
            return old_method_missing(sym, *args, **kwargs, &block)
         end
      end
         



      raise NameError.new "Undefined method: #{class_name}" unless c
 
      widget = c.new({  :args => args,
                        :kwargs => kwargs,
                        :assigns => @assigns },
                        &block)
      return widget.to_s
   end
end  
  
