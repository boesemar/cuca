module Cuca

# A session page (access via session.page) is memory that is only valid 
# for the current action. 
# Query and Request paramenters are automatically available in this container and
# remain available if removed due to a page refresh or similar.
# 
# If you leave the page, they are NOT erased anymore (this used to be cuca behavior
# <= 0.7). They stay valid until EXPIRE_TIME_HOURS (default 4 hours).
#
# see Cuca::Session
class SessionPage

 LAKEY = :session_page_last_access
 EXPIRE_TIME_HOURS = 4

 private 
 def pagekey
   "Pk_#{$app.urlmap.script.gsub(/[\/\\]/, '_')}".intern
 end

 def pagemem
   @ses[:SessionPage]
 end

 public
 def initialize(session)
   @ses = session
   @ses[:SessionPage] ||= {}
   pagemem[pagekey] ||= {}
   pagemem[pagekey][LAKEY] = Time.now
   session.cgi.parameters.each_pair { |k,v|  self[k] = v if v.kind_of?(String) } 
   expire
 end

 def [](key)
    pagemem[pagekey][key]
 end

 def []=(key,value)
    pagemem[pagekey][key] = value
 end

 # remove a variable from page memory
 def delete(key)
    pagemem[pagekey].delete(key)
 end

 # delete all from current page memory 
 def reset
   pagemem[pagekey] = {}
 end

 # access to pagemem
 def memory
   pagemem[pagekey]
 end

 private
 def expire
    pagemem.each_pair do |k,v| 
      next if k == pagekey
      next unless pagemem[k][LAKEY]
      next if pagemem[k][LAKEY] > (Time.now - (3600 * EXPIRE_TIME_HOURS))
      pagemem.delete(k)
    end
 end
 
end

end
