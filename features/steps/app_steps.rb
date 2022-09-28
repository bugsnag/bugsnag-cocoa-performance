# frozen_string_literal: true

When('I run {string}') do |scenario_name|
  Maze::Server.commands.add({ scenario: scenario_name })
  Maze.driver.click_element :execute_command
  # Ensure fixture has read the command
  count = 100
  sleep 0.1 until Maze::Server.commands.remaining.empty? || (count -= 1) < 1
  raise 'Test fixture did not GET /command' unless Maze::Server.commands.remaining.empty?
end

Then('the {word} payload field {string} attribute {string} equals {string}') do |request_type, field, key, expected|
  list = Maze::Server.list_for(request_type)
  attributes = Maze::Helper.read_key_path(list.current[:body], "#{field}.attributes")
  Maze.check.equal attributes.find { |a| a['key'] == key }, { 'key' => key, 'value' => { 'stringValue' => expected } }
end
