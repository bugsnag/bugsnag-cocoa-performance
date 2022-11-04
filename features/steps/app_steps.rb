# frozen_string_literal: true

When('I run {string}') do |scenario_name|
  Maze::Server.commands.add({ scenario: scenario_name })
  Maze.driver.click_element :execute_command
  # Ensure fixture has read the command
  count = 100
  sleep 0.1 until Maze::Server.commands.remaining.empty? || (count -= 1) < 1
  raise 'Test fixture did not GET /command' unless Maze::Server.commands.remaining.empty?
end

Then('the {word} payload field {string} string attribute {string} equals {string}') do |request_type, field, key, expected|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  Maze.check.equal attributes.find { |a| a['key'] == key }, { 'key' => key, 'value' => { 'stringValue' => expected } }
end

Then('the {word} payload field {string} string attribute {string} matches the regex {string}') do |request_type, field, key, regex_string|
  regex = Regexp.new(regex_string)
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  attribute = attributes.find { |a| a['key'] == key }
  value = attribute["value"]["stringValue"]
  Maze.check.match(regex, value)
end

Then('the {word} payload field {string} string attribute {string} equals the stored value {string}') do |request_type, field, attr_key, stored_key|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  attribute = attributes.find { |a| a['key'] == attr_key }
  payload_value = attribute["value"]["stringValue"]
  stored_value = Maze::Store.values[stored_key]
  result = Maze::Compare.value(payload_value, stored_value)
  Maze.check.true(result.equal?, "Payload value: #{payload_value} does not equal stored value: #{stored_value}")
end

Then('the {word} payload field {string} string attribute {string} exists') do |request_type, field, key|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  attribute = attributes.find { |a| a['key'] == key }
  value = attribute["value"]["stringValue"]
  Maze.check.not_nil(value)
end

Then('the {word} payload field {string} integer attribute {string} equals {int}') do |request_type, field, key, expected|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  attribute = attributes.find { |a| a['key'] == key }
  value = attribute["value"]["intValue"].to_i
  Maze.check.equal(expected, value)
end

Then('the {word} payload field {string} integer attribute {string} is greater than {int}') do |request_type, field, key, int_value|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  attribute = attributes.find { |a| a['key'] == key }
  value = attribute["value"]["intValue"].to_i
  Maze.check.operator(value, :>, int_value, "The payload field '#{field}' attribute '#{key}' (#{value}) is not greater than '#{int_value}'")
end
