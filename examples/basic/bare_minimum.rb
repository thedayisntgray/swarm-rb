$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "dotenv/load"
require "swarm"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = Swarm::Swarm.new

agent = Swarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  functions: []
)

messages = [{"role" => "user", "content" => "What is the weather!"}]
response = client.run(agent: agent, messages: messages)

puts response.messages.last["content"]
