require "minitest/autorun"
require_relative "../lib/swarm/util"

class TestUtil < Minitest::Test
  def test_basic_function
    def basic_function(arg1, arg2)
      arg1 + arg2
    end

    result = Swarm::Util.function_to_json(method(:basic_function))

    expected = {
      "name" => "basic_function",
      "description" => "",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "arg1" => {"type" => "string"},
          "arg2" => {"type" => "string"}
        },
        "required" => ["arg1", "arg2"]
      }
    }

    assert_equal expected, result
  end

  def test_complex_function
    def complex_function_with_types_and_descriptions(arg1, arg2, arg3 = 3.14, arg4 = false)
      # This is a complex function with a docstring.
    end

    result = Swarm::Util.function_to_json(method(:complex_function_with_types_and_descriptions))

    expected = {
      "name" => "complex_function_with_types_and_descriptions",
      "description" => "",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "arg1" => {"type" => "string"},
          "arg2" => {"type" => "string"},
          "arg3" => {"type" => "string"},
          "arg4" => {"type" => "string"}
        },
        "required" => ["arg1", "arg2"]
      }
    }

    assert_equal expected, result
  end
end
