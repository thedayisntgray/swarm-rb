require "time"
require "json"

module Swarm
  module Util
    def self.debug_print(debug, *args)
      return unless debug
      timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
      message = args.join(" ")
      puts "\e[97m[\e[90m#{timestamp}\e[97m]\e[90m #{message}\e[0m"
    end

    def self.merge_fields(target, source)
      source.each do |key, value|
        if value.is_a?(String)
          target[key] += value
        elsif value.is_a?(Hash)
          merge_fields(target[key], value)
        end
      end
    end

    def self.merge_chunk(final_response, delta)
      delta.delete("role")
      merge_fields(final_response, delta)

      tool_calls = delta["tool_calls"]
      if tool_calls && !tool_calls.empty?
        index = tool_calls[0].delete("index")
        merge_fields(final_response["tool_calls"][index], tool_calls[0])
      end
    end

    def self.function_to_json(func)
      type_map = {
        String => "string",
        Integer => "integer",
        Float => "number",
        TrueClass => "boolean",
        FalseClass => "boolean",
        Array => "array",
        Hash => "object",
        NilClass => "null"
      }

      parameters = {}
      required = []

      func.parameters.each do |type, name|
        param_type = type_map[name.class] || "string" # Default to 'string' if type is unknown

        if name.to_s == "context_variables" && type == :keyreq
          param_type = "object"
        end

        parameters[name.to_s] = {"type" => param_type}
        required << name.to_s if type == :req || type == :keyreq
      end

      {
        "name" => func.name.to_s,
        "description" => "",
        "parameters" => {
          "type" => "object",
          "properties" => parameters,
          "required" => required
        }
      }
    end
  end
end
