require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'rack'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'

# static files are served from public_path - and only from there
class StaticFilesTest < Test::Unit::TestCase
    def setup
        @dir = Dir.mktmpdir('cuca-static')
        @public = File.join(@dir, 'public')
        FileUtils.mkdir_p(File.join(@public, 'css'))
        File.write(File.join(@public, 'hello.txt'), 'hello world')
        File.write(File.join(@public, 'css', 'site.css'), 'body {}')
        File.write(File.join(@dir, 'secret.txt'), 'TOP SECRET')
        @app = Cuca::App.new(app_path: "#{$cuca_path}/app", public_path: @public, log_path: @dir)
    end

    def teardown
        FileUtils.rm_rf(@dir)
    end

    def get(path)
        @app.rackcall(Rack::MockRequest.env_for(path))
    end

    def test_serves_public_file
        status, headers, body = get('/hello.txt')
        assert_equal 200, status
        assert_equal 'hello world', body.join
        assert_equal 'text/plain', headers['content-type']
    end

    def test_serves_file_in_subdirectory_with_mime_type
        status, headers, body = get('/css/site.css')
        assert_equal 200, status
        assert_equal 'body {}', body.join
        assert_equal 'text/css', headers['content-type']
    end

    def test_does_not_serve_files_outside_public
        [
            '/../secret.txt',
            '/..%2fsecret.txt',
            '/%2e%2e%2fsecret.txt',
            '/css/..%2f..%2fsecret.txt',
        ].each do |path|
            _status, _headers, body = get(path)
            refute_match(/TOP SECRET/, body.join, "served file outside public via #{path}")
        end
    end

    def test_does_not_serve_directory_or_null_byte
        _status, _headers, body = get('/css')
        refute_equal 'body {}', body.join
        _status, _headers, body = get('/hello.txt%00.css')
        refute_equal 'hello world', body.join
    end
end
