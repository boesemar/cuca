# Use this class to define system wide controller class (if you decide to derive
# your controllers from ApplicationController)

require 'cuca/generator/markaby'
class ApplicationController < Cuca::Controller
 include Cuca::Generator::Markaby
end
