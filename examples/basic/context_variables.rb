$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))

require "dotenv/load"
require "swarm"

OpenAI.configure do |config|
  config.access_token = ENV["OPENAI_ACCESS_TOKEN"]
end

client = Swarm::Swarm.new

def instructions(context_variables)
  name = context_variables.fetch("name", "User")
  "You are a helpful agent. Greet the user by name (#{name})."
end

def print_account_details(context_variables: {})
  user_id = context_variables["user_id"]
  name = context_variables["name"]
  puts "Account Details: #{name} #{user_id}"
  "Success"
end

agent = Swarm::Agent.new(
  name: "Agent",
  instructions: method(:instructions),
  functions: [method(:print_account_details)]
)

context_variables = {"name" => "James", "user_id" => 123}

response = client.run(
  messages: [{"role" => "user", "content" => "Hi!"}],
  agent: agent,
  context_variables: context_variables
)
puts response.messages.last["content"]

response = client.run(
  messages: [{"role" => "user", "content" => "Print my account details!"}],
  agent: agent,
  context_variables: context_variables
)
puts response.messages.last["content"]
