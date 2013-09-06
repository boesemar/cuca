# this action will show some widgets


require 'cuca/stdlib/list' # this will include the StaticDataListWidget
require 'cuca/stdlib/link' # to use the LinkWidget


class DemoController < ApplicationController

layout 'simple'

def run
  @page_title = "Example use of a Widget"
  @script     = app.urlmap.script
  mab do
     h1 { "A few widgets" }
     br
     i { "Please have a look at the page sourcecode below so these mixed examples make sense" }
     br
     br
    
     # LinkWidget 1
     h2 { "This is a simple Link" }
     Link('index') { "This is a Link back to Index" }
     br
     
     # LinkWidget 2
     h2 { "Also the following block is one link, but with markaby code as content that displays the bird and the script filename" }
     Link('index', {}) { img(:src=>'/img/cuca-seagull.png'); br; text "Rendered with #{@script}" }
     br
     
     # Static Data List
     h2 { "This is a demo of the List widget using Static Data" }
     small { "Note: You can sort, browse and filter this list" }
     StaticDataList('random_names',
           :columns => [ { :id => 'id',    :display=>'ID #' },
                         { :id => 'name',  :display=>'Name' } ],
           :data    => [[ 1, 'Jack'],
                        [ 2, 'Elvis'],
                        [ 3, 'Alice'],
                        [ 4, 'John'],
                        [ 5, 'Elwood'],
                        [ 6, 'Jake'],
                        [ 7, 'Purple'],
                        [ 8, 'Nicci'],
                        [ 9, 'Feti'],
                        [ 10, 'Fella'],
                        [ 11, 'Scott'],
                        [ 12, 'Leo']])
     br

     # TestWidget
     h2 {"The 'TestWidget' will take any parameter and any block and will display how we called it: " } 
     Test("one", 2, 'tree') { b { "a bold block with a string" }}
     br

     # SourceCode
     h2 { "Finally this is the sourcecode of the script" }
     SourceCode();
     br
  end
end

end
