#!/usr/bin/ruby
# A simple irb session that loads the cuca framework

libs  = " -r irb/completion -r rubygems -r cuca -r cuca_console"
exec "irb #{libs} --simple-prompt"
