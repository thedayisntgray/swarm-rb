require "minitest/autorun"
require_relative "../lib/swarm"
require_relative "mock_client"

class TestCore < Minitest::Test
  DEFAULT_RESPONSE_CONTENT = "sample response content"

  def setup
    @mock_client = MockOpenAIClient.new
  end

  def test_run_with_simple_message
    agent = Swarm::Agent.new(
      name: "Test Agent",
      instructions: "You are a helpful assistant."
    )

    @mock_client.set_response(
      create_mock_response(message: {role: "assistant", content: DEFAULT_RESPONSE_CONTENT})
    )

    client = Swarm::Swarm.new(@mock_client)

    messages = [{"role" => "user", "content" => "Hello, how are you?"}]
    response = client.run(agent: agent, messages: messages)

    last_message = response.messages.last
    assert_equal "assistant", last_message["role"]
    assert_equal DEFAULT_RESPONSE_CONTENT, last_message["content"]
  end

  def test_tool_call
    expected_location = "San Francisco"

    @get_weather_calls = []

    define_singleton_method(:get_weather_tool_call) do |location:|
      @get_weather_calls << {location: location}
      "It's sunny today."
    end

    agent = Swarm::Agent.new(
      name: "Test Agent",
      functions: [method(:get_weather_tool_call)]
    )

    messages = [{"role" => "user", "content" => "What's the weather like in #{expected_location}?"}]

    @mock_client.set_sequential_responses([
      create_mock_response(
        message: {role: "assistant", content: nil, function_call: {"name" => "get_weather_tool_call", "arguments" => "{ \"location\": \"#{expected_location}\" }"}}
      ),
      create_mock_response(message: {role: "assistant", content: DEFAULT_RESPONSE_CONTENT})
    ])

    client = Swarm::Swarm.new(@mock_client)

    response = client.run(agent: agent, messages: messages)

    assert_equal 1, @get_weather_calls.size
    assert_equal({location: expected_location}, @get_weather_calls[0])

    last_message = response.messages.last
    assert_equal "assistant", last_message["role"]
    assert_equal DEFAULT_RESPONSE_CONTENT, last_message["content"]
  end

  def test_execute_tools_false
    expected_location = "San Francisco"

    @get_weather_calls = []

    define_singleton_method(:get_weather_execute_false) do |location:|
      @get_weather_calls << {location: location}
      "It's sunny today."
    end

    agent = Swarm::Agent.new(
      name: "Test Agent",
      functions: [method(:get_weather_execute_false)]
    )

    messages = [{"role" => "user", "content" => "What's the weather like in #{expected_location}?"}]

    @mock_client.set_sequential_responses([
      create_mock_response(
        message: {role: "assistant", content: nil, function_call: {"name" => "get_weather_execute_false", "arguments" => "{ \"location\": \"#{expected_location}\" }"}}
      )
    ])

    client = Swarm::Swarm.new(@mock_client)

    response = client.run(agent: agent, messages: messages, execute_tools: false)

    assert_equal 0, @get_weather_calls.size

    last_message = response.messages.last
    assert_equal "assistant", last_message["role"]
    assert_nil last_message["content"]
    assert_equal "get_weather_execute_false", last_message["function_call"]["name"]
    assert_equal({"location" => expected_location}, JSON.parse(last_message["function_call"]["arguments"]))
  end

  def test_agent_handoff
    define_singleton_method(:transfer_to_agent2) do |context_variables = {}|
      @agent2
    end

    @agent2 = Swarm::Agent.new(
      name: "Agent 2",
      instructions: "You are Agent 2."
    )

    agent1 = Swarm::Agent.new(
      name: "Agent 1",
      instructions: "You are Agent 1.",
      functions: [method(:transfer_to_agent2)]
    )

    messages = [{"role" => "user", "content" => "I want to talk to agent 2."}]

    @mock_client.set_sequential_responses([
      create_mock_response(
        message: {role: "assistant", content: nil, function_call: {"name" => "transfer_to_agent2", "arguments" => "{}"}}
      ),
      create_mock_response(message: {role: "assistant", content: DEFAULT_RESPONSE_CONTENT})
    ])

    client = Swarm::Swarm.new(@mock_client)

    response = client.run(agent: agent1, messages: messages)

    assert_equal @agent2, response.agent

    last_message = response.messages.last
    assert_equal "assistant", last_message["role"]
    assert_equal DEFAULT_RESPONSE_CONTENT, last_message["content"]
  end
end
