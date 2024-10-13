require "json"
require_relative "core"
require "dotenv/load"

module Swarm
  module Repl
    def self.process_and_print_streaming_response(response)
      content = ""
      last_sender = ""

      response.each do |chunk|
        if chunk["sender"]
          last_sender = chunk["sender"]
        end

        if chunk["content"]
          if content.empty? && last_sender
            print "\e[94m#{last_sender}:\e[0m "
            last_sender = ""
          end
          print chunk["content"]
          content += chunk["content"]
        end

        chunk["tool_calls"]&.each do |tool_call|
          func = tool_call["function"]
          name = func["name"]
          next unless name
          puts "\e[94m#{last_sender}: \e[95m#{name}\e[0m()"
        end

        if chunk["delim"] == "end" && !content.empty?
          puts
          content = ""
        end

        return chunk["response"] if chunk["response"]
      end
    end

    def self.pretty_print_messages(messages)
      messages.each do |message|
        next unless message["role"] == "assistant"

        # Print agent name in blue
        print "\e[94m#{message["sender"]}\e[0m: "

        puts message["content"] if message["content"]

        tool_calls = message["tool_calls"] || []
        puts if tool_calls.length > 1
        tool_calls.each do |tool_call|
          func = tool_call["function"]
          name = func["name"]
          args = JSON.parse(func["arguments"] || "{}").map { |k, v| "#{k}=#{v}" }.join(", ")
          puts "\e[95m#{name}\e[0m(#{args})"
        end
      end
    end

    def self.run_demo_loop(
      starting_agent,
      context_variables = nil,
      stream = false,
      debug = false
    )
      client = Swarm.new
      puts "Starting Swarm CLI \u{1F41D}"

      messages = []
      agent = starting_agent

      loop do
        print "\e[90mUser\e[0m: "
        user_input = gets.chomp
        messages << {"role" => "user", "content" => user_input}

        response = client.run(
          agent: agent,
          messages: messages,
          context_variables: context_variables || {},
          stream: stream,
          debug: debug
        )

        if stream
          response = process_and_print_streaming_response(response)
        else
          pretty_print_messages(response.messages)
        end

        messages.concat(response.messages)
        agent = response.agent
      end
    end
  end
end
