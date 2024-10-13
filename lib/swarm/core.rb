require "openai"
require "json"
require_relative "util"
require_relative "types"

module Swarm
  class Swarm
    CTX_VARS_NAME = "context_variables"

    def initialize(client = nil)
      @client = client || OpenAI::Client.new
    end

    def get_chat_completion(
      agent:,
      history:,
      context_variables:,
      model_override: nil,
      stream: false,
      debug: false
    )
      context_variables = context_variables.dup
      instructions = if agent.instructions.respond_to?(:call)
        agent.instructions.call(context_variables)
      else
        agent.instructions
      end

      messages = [{"role" => "system", "content" => instructions}] + history
      Util.debug_print(debug, "Getting chat completion for:", messages)

      tools = agent.functions.map { |f| Util.function_to_json(f) }

      # Hide context_variables from the model
      tools.each do |tool|
        puts tool
        params = tool["parameters"]
        params["properties"]&.delete(CTX_VARS_NAME)
        params["required"]&.delete(CTX_VARS_NAME)
      end

      parameters = {
        model: model_override || agent.model,
        messages: messages
      }

      parameters[:functions] = tools unless tools.empty?
      parameters[:function_call] = agent.tool_choice if agent.tool_choice
      parameters[:stream] = stream

      Util.debug_print(debug, "Chat parameters:", parameters)

      begin
        if stream
          @client.chat(parameters: parameters) do |chunk|
            # Handle streaming response if needed
          end
        else
          response = @client.chat(parameters: parameters)
          Util.debug_print(debug, "API Response:", response)
          response
        end
      rescue OpenAI::Error => e
        Util.debug_print(true, "OpenAI API Error:", e.message)
        raise
      end
    end

    def handle_function_result(result, debug)
      case result
      when Result
        result
      when Agent
        Result.new(value: {"assistant" => result.name}.to_json, agent: result)
      else
        begin
          Result.new(value: result.to_s)
        rescue => e
          error_message = "Failed to cast response to string: #{result}. Make sure agent functions return a string or Result object. Error: #{e.message}"
          Util.debug_print(debug, error_message)
          raise TypeError, error_message
        end
      end
    end

    def handle_tool_calls(tool_calls, functions, context_variables, debug)
      function_map = functions.map { |f| [f.name.to_s, f] }.to_h
      partial_response = Response.new(messages: [], agent: nil, context_variables: {})

      tool_calls.each do |tool_call|
        name = tool_call["name"]
        unless function_map.key?(name)
          Util.debug_print(debug, "Tool #{name} not found in function map.")
          partial_response.messages << {
            "role" => "function",
            "name" => name,
            "content" => "Error: Tool #{name} not found."
          }
          next
        end

        args = JSON.parse(tool_call["arguments"] || "{}")
        Util.debug_print(debug, "Processing tool call: #{name} with arguments #{args}")

        func = function_map[name]
        # Pass context_variables to agent functions
        if func.parameters.map(&:last).include?(CTX_VARS_NAME.to_sym)
          args[CTX_VARS_NAME] = context_variables
        end

        raw_result = func.call(**args.transform_keys(&:to_sym))
        result = handle_function_result(raw_result, debug)
        partial_response.messages << {
          "role" => "function",
          "name" => name,
          "content" => result.value
        }
        partial_response.context_variables.merge!(result.context_variables)
        partial_response.agent ||= result.agent
      end

      partial_response
    end

    def run(
      agent:,
      messages:,
      context_variables: {},
      model_override: nil,
      stream: false,
      debug: false,
      max_turns: Float::INFINITY,
      execute_tools: true
    )
      if stream
        run_and_stream(
          agent: agent,
          messages: messages,
          context_variables: context_variables,
          model_override: model_override,
          debug: debug,
          max_turns: max_turns,
          execute_tools: execute_tools
        )
      else
        active_agent = agent
        context_variables = context_variables.dup
        history = messages.dup
        init_len = messages.length

        while (history.length - init_len) < max_turns && active_agent
          completion = get_chat_completion(
            agent: active_agent,
            history: history,
            context_variables: context_variables,
            model_override: model_override,
            stream: stream,
            debug: debug
          )

          message = completion["choices"][0]["message"]
          Util.debug_print(debug, "Received completion:", message)
          message["sender"] = active_agent.name
          history << message

          unless message["function_call"] && execute_tools
            Util.debug_print(debug, "Ending turn.")
            break
          end

          tool_calls = [message["function_call"]]
          partial_response = handle_tool_calls(
            tool_calls, active_agent.functions, context_variables, debug
          )
          history.concat(partial_response.messages)
          context_variables.merge!(partial_response.context_variables)
          active_agent = partial_response.agent if partial_response.agent
        end

        Response.new(
          messages: history[init_len..],
          agent: active_agent,
          context_variables: context_variables
        )
      end
    end

    def run_and_stream(
      agent:,
      messages:,
      context_variables: {},
      model_override: nil,
      debug: false,
      max_turns: Float::INFINITY,
      execute_tools: true
    )
    end
  end
end
