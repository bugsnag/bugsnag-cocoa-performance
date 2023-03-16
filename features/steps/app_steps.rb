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

Then('every span field {string} equals {int}') do |key, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_keys = spans.map { |span| span[key] == expected }
  Maze.check.not_includes selected_keys, false
end

Then('every span bool attribute {string} is false') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze::check.false span['attributes'].find { |a| a['key'] == attribute }['value']['boolValue'] }
end
