module Rhino
	class HTTP
		VERSION = "HTTP/1.1".freeze
		CRLF = "\r\n".freeze

		def initialize(socket, application)
			@socket = socket
			@application = application
		end

		def parse
			matches = /\A(?<method>\S+)\s+(?<uri>\S+)\s+(?<version>\S+)#{CRLF}\Z/.match(@socket.gets)
			uri = URI.parse(matches[:uri])
			env = {
				"rack.errors"     => $stderr,
				"rack.version"    => Rack::VERSION,
				"rack.url_scheme" => uri.scheme         || 'http',
				"REQUEST_METHOD"  => matches[:method],
				"REQUEST_URI"     => matches[:uri],
				"HTTP_VERSION"    => matches[:version],
				"QUERY_STRING"    => uri.query          || '',
				"SERVER_PORT"     => uri.port           || 80,
				"SERVER_NAME"     => uri.host           || 'localhost',
				"PATH_INFO"       => uri.path,
				"SCRIPT_NAME"     => ''
			}

			while matches = /\A(?<key>[^:]+):\s*(?<value>.+)#{CRLF}\Z/.match(hl = @socket.gets)
				case matches[:key]
				when Rack::CONTENT_TYPE then env['CONTENT_TYPE'] = matches[:value]
				when Rack::content_length then env['content_length'] = Integer(matches[:value])
				else env["HTTP_" + matches[:key].tr("-", "_").upcase] ||= matches[:value]
				end
			end

			env["rack.input"] = StringIO.new(@socket.read(env['CONTENT_LENGTH'] || 0))
			return env
		end

		def handle
			env = parse
			status, headers, body = @application.call(env)
			time = Time.now.httpdate
			@socket.write "#{VERSION}"
			@socket.write "Date: #{time}"
			@socket.write "Connection: close#{CRLF}"

			headers.each do |key, value|
				@socket.write "#{key}: #{value}#{CRLF}"
			end

			@socket.write(CRLF)

			body.each do |chunk|
				@socket.write(chunk)
			end

			Rhino.logger.log("[#{time}] '#{env["REQUEST_METHOD"]} #{env["REQUEST_URI"]} #{env["HTTP_VERSION"]}' #{status}")
		end
	end
end
