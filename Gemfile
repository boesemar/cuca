source 'https://rubygems.org'

gemspec

# markaby fork used by m3ms-3 (ruby 3.2 fixes, helper output, with_output)
gem 'markaby', git: 'https://github.com/boesemar/markaby'
# markaby needs Builder::BlankSlate, which was removed in builder 3.3
gem 'builder', '~> 3.2.0'

group :test do
    gem 'test-unit'
    gem 'rack', '~> 2'
end
