require_relative '../handler'
require 'test-unit'

class TestHandler < Test::Unit::TestCase
  def test_happy_path
    response = hello(event: {}, context: {})
    assert_equal 200, response[:statusCode]
    assert_match /Serverless/, response[:body]
  end
end
