$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "dotenv/load"
require "swarm"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = Swarm::Swarm.new

english_agent = Swarm::Agent.new(
  name: "English Agent",
  instructions: "You only speak English.",
  model: "gpt-4"
)

spanish_agent = Swarm::Agent.new(
  name: "Spanish Agent",
  instructions: "You only speak Spanish.",
  model: "gpt-4"
)

def transfer_to_spanish_agent(context_variables = {})
  # Transfer Spanish-speaking users immediately
  $spanish_agent
end

$spanish_agent = spanish_agent

english_agent.functions << method(:transfer_to_spanish_agent)

messages = [{"role" => "user", "content" => "Hola. ¿Como estás?"}]

response = client.run(agent: english_agent, messages: messages, debug: true)

puts response.inspect

if response&.messages&.any?
  last_message = response.messages.last
  puts last_message["content"] || "No content in the last message."
else
  puts "No messages received."
end
