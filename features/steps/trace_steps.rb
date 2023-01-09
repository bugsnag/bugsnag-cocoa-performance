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
    And I wait to receive at least 1 trace
    And the trace payload field "resourceSpans" is an array with 0 elements
    And I discard the oldest trace
  }
end

When('I wait for {int} span(s)') do |span_count|
  assert_received_spans span_count, Maze::Server.list_for('traces')
end

Then('every span field {string} equals {string}') do |key, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] == expected }
  Maze.check.not_includes selected_keys, false
end

Then('every span field {string} matches the regex {string}') do |key, pattern|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.match pattern, span[key] }
end

Then('every span string attribute {string} exists') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.not_nil span['attributes'].find { |a| a['key'] == attribute }['value']['stringValue'] }
end

Then('every span string attribute {string} equals {string}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.equal expected, span['attributes'].find { |a| a['key'] == attribute }['value']['stringValue'] }
end

Then('every span string attribute {string} matches the regex {string}') do |attribute, pattern|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.match pattern, span['attributes'].find { |a| a['key'] == attribute }['value']['stringValue'] }
end

Then('every span integer attribute {string} is greater than {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze::check.true span['attributes'].find { |a| a['key'] == attribute }['value']['intValue'].to_i > expected }
end

Then('every span bool attribute {string} is true') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze::check.true span['attributes'].find { |a| a['key'] == attribute }['value']['boolValue'] }
end

Then('a span string attribute {string} exists') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'] == attribute }['value']['stringValue'] }
  Maze.check.false(selected_attributes.empty?)
end

Then('a span string attribute {string} equals {string}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'] == attribute }['value']['stringValue'] }
  Maze.check.includes selected_attributes, expected
end

Then('a span field {string} equals {string}') do |key, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] }
  Maze.check.includes selected_keys, expected
end

Then('a span field {string} matches the regex {string}') do |attribute, pattern|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| Maze.check.match pattern, span[attribute] }
  Maze.check.false(selected_attributes.empty?)
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

def assert_received_spans(span_count, list)
  timeout = Maze.config.receive_requests_wait
  wait = Maze::Wait.new(timeout: timeout)

  received = wait.until { spans_from_request_list(list).size >= span_count }
  received_count = spans_from_request_list(list).size

  unless received_count == span_count
    raise Test::Unit::AssertionFailedError.new <<-MESSAGE
    Expected #{span_count} spans but received #{received_count} within the #{timeout}s timeout.
    This could indicate that:
    - Bugsnag crashed with a fatal error.
    - Bugsnag did not make the requests that it should have done.
    - The requests were made, but not deemed to be valid (e.g. missing integrity header).
    - The requests made were prevented from being received due to a network or other infrastructure issue.
    Please check the Maze Runner and device logs to confirm.)
    MESSAGE
  end

  Maze.check.operator(span_count, :<=, received_count, "#{received_count} spans received")
end

def spans_from_request_list list
  return list.remaining
             .flat_map { |req| req[:body]['resourceSpans'] }
             .flat_map { |r| r['scopeSpans'] }
             .flat_map { |s| s['spans'] }
             .select { |s| !s.nil? }
end
