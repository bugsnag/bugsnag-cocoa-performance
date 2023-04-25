# frozen_string_literal: true

When('I run {string}') do |scenario_name|
  Maze::Server.commands.add({ scenario: scenario_name })
  Maze.driver.click_element :execute_command
  # Ensure fixture has read the command
  count = 100
  sleep 0.1 until Maze::Server.commands.remaining.empty? || (count -= 1) < 1
  raise 'Test fixture did not GET /command' unless Maze::Server.commands.remaining.empty?
end

When("I run {string} and discard the initial p-value request") do |scenario|
  steps %Q{
    When I run "#{scenario}"
    And I receive and discard the initial p-value request
  }
end

# Note:
# every = every single span must have this field, and each must match the expected value
# all   = every span that has this field must match the expected value
# a     = at least one span must have this field that matches the expected value

Then('every span field {string} equals {int}') do |key, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] == expected }
  Maze.check.not_includes selected_keys, false
end

Then('every span field {string} does not exist') do |key|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['key'] }
end

Then('every span bool attribute {string} is false') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze::check.false span['attributes'].find { |a| a['key'] == attribute }['value']['boolValue'] }
end

Then('every span bool attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['attributes'].find { |a| a['key'] == attribute } }
end

Then('every span string attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['attributes'].find { |a| a['key'] == attribute } }
end

Then('all span bool attribute {string} is true') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('boolValue') } }.compact
  selected_attributes.map { |a| Maze::check.true a['value']['boolValue'] }
end

Then('a span bool attribute {string} is true') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('boolValue') } }.compact
  selected_attributes = selected_attributes.map { |a| a['value']['boolValue'] == true }
  Maze.check.false(selected_attributes.empty?)
end

Then('all span bool attribute {string} is false') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('boolValue') } }.compact
  selected_attributes.map { |a| Maze::check.false a['value']['boolValue'] }
end

Then('a span bool attribute {string} is false') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('boolValue') } }.compact
  selected_attributes = selected_attributes.map { |a| a['value']['boolValue'] == false }
  Maze.check.false(selected_attributes.empty?)
end

Then('a span field {string} is greater than {int}') do |key, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] and span[key].to_i > expected }
  Maze.check.false(selected_keys.empty?)
end

Then('a span field {string} exists') do |key|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] }
  Maze.check.false(selected_keys.empty?)
end

Then('a span field {string} does not exist') do |key|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| !span[key] }
  Maze.check.false(selected_keys.empty?)
end

Then('a span bool attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| !span['attributes'].find { |a| a['key'] == attribute } }
  Maze.check.false(selected_keys.empty?)
end

Then('a span string attribute {string} matches the regex {string}') do |attribute, pattern|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('stringValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['stringValue'] }
  attribute_values.map { |v| Maze.check.match pattern, v }
end

Then('a span integer attribute {string} is greater than {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['intValue'].to_i > expected }
  Maze.check.false(attribute_values.empty?)
end
