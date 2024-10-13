require "json"
require "ostruct"

class MockOpenAIClient
  def initialize
    @responses = []
    @call_count = 0
  end

  def set_response(response)
    @responses = [response]
  end

  def set_sequential_responses(responses)
    @responses = responses
  end

  def chat(parameters:)
    response = @responses[@call_count]
    @call_count += 1

    OpenStruct.new(response)
  end

  def reset
    @call_count = 0
  end
end

def create_mock_response(message:, function_calls: nil, model: "gpt-4")
  role = message[:role] || "assistant"
  content = message[:content]
  function_call = message[:function_call]

  choice = {
    "index" => 0,
    "message" => {
      "role" => role,
      "content" => content
    },
    "finish_reason" => "stop"
  }

  if function_call
    choice["message"]["function_call"] = function_call
  end

  {
    "id" => "mock_response_id",
    "object" => "chat.completion",
    "created" => Time.now.to_i,
    "model" => model,
    "choices" => [choice],
    "usage" => {
      "prompt_tokens" => 10,
      "completion_tokens" => 10,
      "total_tokens" => 20
    }
  }
end
