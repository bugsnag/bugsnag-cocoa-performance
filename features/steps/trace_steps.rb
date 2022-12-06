# frozen_string_literal: true

Then('the trace payload field {string} bool attribute {string} is true') do |field, attribute|
  check_attribute_equal field, attribute, 'boolValue', true
end

Then('the trace payload field {string} bool attribute {string} is false') do |field, attribute|
  check_attribute_equal field, attribute, 'boolValue', false
end

Then('the trace payload field {string} integer attribute {string} equals {int}') do |field, attribute, expected|
  check_attribute_equal field, attribute, 'stringValue', expected
end

Then('the trace payload field {string} integer attribute {string} is greater than {int}') do |field, attribute, expected|
  value = get_attribute_value field, attribute, 'intValue'
  Maze.check.operator value, :>, expected,
                      "The payload field '#{field}' attribute '#{attribute}' (#{value}) is not greater than '#{expected}'"
end

Then('the trace payload field {string} string attribute {string} equals {string}') do |field, attribute, expected|
  check_attribute_equal field, attribute, 'stringValue', expected
end

Then('the trace payload field {string} string attribute {string} equals the stored value {string}') do |field, attribute, stored_key|
  value = get_attribute_value field, attribute, 'stringValue'
  stored = Maze::Store.values[stored_key]
  result = Maze::Compare.value value, stored
  Maze.check.true result.equal?, "Payload value: #{value} does not equal stored value: #{stored}"
end

Then('the trace payload field {string} string attribute {string} matches the regex {string}') do |field, attribute, pattern|
  value = get_attribute_value field, attribute, 'stringValue'
  regex = Regexp.new pattern
  Maze.check.match regex, value
end

Then('the trace payload field {string} string attribute {string} exists') do |field, attribute|
  value = get_attribute_value field, attribute, 'stringValue'
  Maze.check.not_nil value
end

Then("I run {string} and discard the initial p-value request") do |scenario|
  steps %Q{
    When I run "#{scenario}"
    And I wait to receive a trace
    And the trace payload field "resourceSpans" is an array with 0 elements
    And I discard the oldest trace
  }
end

def get_attribute_value(field, attribute, attr_type)
  list = Maze::Server.list_for 'trace'
  attributes = Maze::Helper.read_key_path list.current[:body], "#{field}.attributes"
  attribute = attributes.find { |a| a['key'] == attribute }
  value = attribute&.dig 'value', attr_type
  attr_type == 'intValue' && value.is_a?(String) ? value.to_i : value
end

def check_attribute_equal(field, attribute, attr_type, expected)
  value = get_attribute_value field, attribute, attr_type
  Maze.check.equal value, expected
end
