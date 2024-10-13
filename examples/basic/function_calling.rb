$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "dotenv/load"
require "swarm"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = Swarm::Swarm.new

def get_weather(location:)
  # Simulate fetching weather data
  "{'temp':67, 'unit':'F'}"
end

agent = Swarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent.",
  functions: [method(:get_weather)],
  model: "gpt-4"
)

messages = [{"role" => "user", "content" => "What's the weather in NYC?"}]

response = client.run(agent: agent, messages: messages, debug: true)

puts response.inspect

if response&.messages&.any?
  last_message = response.messages.last
  puts last_message["content"] || "No content in the last message."
else
  puts "No messages received."
end
