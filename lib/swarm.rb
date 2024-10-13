require "dotenv"
Dotenv.load

module Swarm
  require_relative "swarm/core"
  require_relative "swarm/types"
  require_relative "swarm/util"
  require_relative "swarm/repl"
end
