# == Simple, fast link - no markaby as block
#
# = Example:
#  mab { SLink('http://cuca.rubyforge.net', 'click') }
#
class SLinkWidget < Cuca::Widget
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


 public
 def output(target, text = nil, params = {}, tag_attrib = {}) 
   @attribs = tag_attrib
   @attribs[:href] = build_href(target, params) 
  
   @_content = "<a "
   @attribs.each_pair do |k,v| 
      @_content << "#{k}='#{v}'"
   end
   @_content << ">#{text || target}</a>"

 end
end
