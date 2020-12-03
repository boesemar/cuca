$:<<'/home/bones/git/cuca/lib/'
require 'cuca'

class CucaApplication
    def call(env)
        Cuca::App.new.rackcall(env)
    end
end

require 'rack/session/pool'

cuca = CucaApplication.new
sessioned = Rack::Session::Pool.new(cuca, :expire_after => 1200)

app = Rack::Builder.new do |builder|
    builder.run sessioned
end

run app
