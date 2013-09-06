# = Cuca - a web application framework
#
# Cuca is another web application framework written in Ruby. It's made to
# build applications with focus on functionality - less design. You can
# create and application without writing HTML. Once written Widgets
# (a smart screen element) can be reused thorough your project with 
# minimum effort allowing to build fast and secure web applications.
#
# It implements the following concepts:
# * A Widget is a screen element. Can be a full page or part of it.
#   The Controller and the Layout are Widgets, too.
# * A Controller deals with one request URI (get, post or both) and can set variables
#   other widgets can make use of. It can also define a Layout and filters.
# * A Layout wraps the output of a controller and finally return the
#   built web page.
# * A Generator (NOT "code generator") can be used within any Widget to help building the web content.
#   Cuca comes with a Markaby and eruby Generator.
# * A Session can used optionally to keep stateful data.
#
#
# == Installation & Getting started
#
# Download and install from the internet:
#
#  gem install --remote cuca
#
#
# Create an application skeleton:
#
#  cuca my_project		# this will create a new project
#  cd my_project
#  ruby ./script/server-webrick.rb
#
# Open http://localhost:2000/
#
#
# == Read on
#
# * Cuca::Widget
# * Cuca::Controller
# * Cuca::Layout
# * Cuca::Session
# * Cuca::App
