module Rhino
	class Logger
		def initialize(stream = STDOUT)
			@stream = stream
		end

		def log(message)
			@stream.puts message
		end
	end
end