desc 'Run the cuca test suite'
task :test do
    ruby File.expand_path('tests/all.rb', __dir__)
end

desc 'Build the cuca gem'
task :build do
    sh 'gem build cuca.gemspec'
end

task default: :test
