module Cuca

# Whatever you write into flash will be valid for the current and for the
# next http request. You can keep the content for another cycle by calling the 
# keep method. Access via session.flash. (See Cuca::Session)
class SessionFlash
 class SessionFlashItem # :nodoc:
    def value
        @value
    end
    def initialize(val)
        @value = val
        @cyc  = 0
    end
    def inc
       @cyc+=1
    end
    def expired?
       @cyc > 1
    end
    def keep
      @cyc=@cyc-1
    end
 end

 private
 def flashmem
   @ses[:SessionFlash]
 end

 public
 def initialize(session)
    @ses = session
    @ses[:SessionFlash] ||= {}
    expire
 end
 
 def [](key)
    flashmem[key] ? flashmem[key].value : nil
 end

 def []=(key, value)
    flashmem[key] = SessionFlashItem.new(value)
 end

 def keep
    flashmem.each_pair { |k,v| v.keep }
 end

 private
 def expire
   flashmem.each_pair do |k,v| 
         v.inc
         flashmem.delete(k) if v.expired?
   end
 end
end

end