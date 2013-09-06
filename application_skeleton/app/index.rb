# This index demo will just output some text using Markaby

require 'cuca/stdlib/slink'

class IndexController < ApplicationController
 layout 'simple'
 
 def run
  @page_title = "Welcome"
  mab do 
    img(:src=>'/img/cuca-seagull.png', :alt=>"Cuca Bird");
    br
    h1 { "Welcome to Cuca" }
    br
    text "Thank you for installing the cuca framework.";br;
    br
    h2 { "If you want to learn cuca" }
    ul do 
     li { text "Have a look at the Demo Widgets: "; SLink('demo', 'Here') }
     li { text "Checkout the cuca website: "; SLink("http://cuca.rubyforge.net") }
     li { text "Read the source code of these examples" }
    end

    h2 { "If you want to start a new application" }
    text "This skeleton comes with a few examples you might want to cleanup. Mainly:"
    ul do 
       li { "Delete app/_widgets/*" }
       li { "Delete app/demo.rb and app/index.rb" }
       li { "Delete app/_layout/*" }
       li { "Look at public/css/style.css" }
       li { "Look at app/_controllers/application.rb" }
    end
    br
    h2 { "Good Luck..." }
    text "If you like cuca use rubyforge to give any type of feedback."
  end
 end
end

