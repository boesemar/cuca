require 'cuca/generator/markaby'


# == A markaby link
# WARNING: This is a very slow way of creating a link. Better to use 
#    SLinkWidget if you call this many times per page!
#
# = Example:
#
#  mab { Link('http://cuca.rubyforge.org') { b { "Click here" } }
#
class LinkWidget < Cuca::Widget

 include Cuca::Generator::Markaby

 private
 def build_href(target, params)
    r = target
   
    r=r+"?" unless params.empty?

    params.each_key do |key|
     r = r + '&' unless r[r.size-1].chr == '?'
     r = "#{r}#{key}=#{params[key]}"
    end
    return r
 end

# public
# def output(target, params = {}, tag_attrib = {}, &block)
#
# end


 public
 def output(target, params = {}, tag_attrib = {}, &block) 
   @attribs = tag_attrib
   @attribs[:href] = build_href(target, params) 
   @block = block
   mab {
        a(@attribs)  { text capture(&block) }
   }
 end
end
