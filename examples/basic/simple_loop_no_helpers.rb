$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "dotenv/load"
require "swarm"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = Swarm::Swarm.new

my_agent = Swarm::Agent.new(
  name: "Agent",
  instructions: "You are a helpful agent."
)

def pretty_print_messages(messages)
  messages.each do |message|
    next unless message["content"]
    puts "#{message["sender"]}: #{message["content"]}"
  end
end

messages = []
agent = my_agent
loop do
  print "> "
  user_input = gets.chomp
  messages << {"role" => "user", "content" => user_input}

  response = client.run(agent: agent, messages: messages)

  messages.concat(response.messages)
  agent = response.agent if response.agent
  pretty_print_messages(response.messages)
end
