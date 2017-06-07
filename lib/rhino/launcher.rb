module Rhino
	class Launcher
		def initialize(port, bind, reuseaddr, backlog, config)
			@port = port
			@bind = bind
			@reuseaddr = reuseaddr
			@backlog = backlog
			@config = config
		end

		def run
			Rhino.logger.log("Rhino")
			Rhino.logger.log("#{@bind}:#{@port}")

			begin
				socket = Socket.new(:INET, :STREAM)
				socket.setsockopt(:SOL_SOCKET, :SO_REUSEADDR, @reuseaddr)
				socket.bind(Addrinfo.tcp(@bind, @port))
				socket.listen(@backlog)

				server = Rhino::Server.new(application, [socket])
				server.run
			ensure
				socket.close
			end
		end

		private
		def application
			raw = File.read(@config)
			builder = <<~BUILDER
Rake::Builder.new do
	#{raw}
BUILDER
eval(builder, nil, @config)
		end

	end
end