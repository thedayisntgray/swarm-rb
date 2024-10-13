module Swarm
  class Agent
    attr_accessor :name, :model, :instructions, :functions, :tool_choice, :parallel_tool_calls

    def initialize(
      name: "Agent",
      model: "gpt-4",
      instructions: "You are a helpful agent.",
      functions: [],
      tool_choice: nil,
      parallel_tool_calls: true
    )
      @name = name
      @model = model
      @instructions = instructions
      @functions = functions
      @tool_choice = tool_choice
      @parallel_tool_calls = parallel_tool_calls
    end
  end

  class Response
    attr_accessor :messages, :agent, :context_variables

    def initialize(messages: [], agent: nil, context_variables: {})
      @messages = messages
      @agent = agent
      @context_variables = context_variables
    end
  end

  class Result
    attr_accessor :value, :agent, :context_variables

    def initialize(value: "", agent: nil, context_variables: {})
      @value = value
      @agent = agent
      @context_variables = context_variables
    end
  end
end
