# frozen_string_literal: true

def skip_above(os, version)
  skip_this_scenario("Skipping scenario") if Maze::Helper.get_current_platform == os and Maze.config.os_version > version
end

def skip_below(os, version)
  skip_this_scenario("Skipping scenario") if Maze::Helper.get_current_platform == os and Maze.config.os_version < version
end

def skip_between(os, version_lo, version_hi)
  skip_this_scenario("Skipping scenario") if Maze::Helper.get_current_platform == os and Maze.config.os_version >= version_lo and Maze.config.os_version <= version_hi
end

Before('@skip_below_ios_15') do |_scenario|
  skip_below('ios', 15.00)
end

Before('@skip_ios_15_and_above') do |_scenario|
  skip_above('ios', 14.99)
end

Then('I discard every {request_type}') do |request_type|
  until Maze::Server.list_for(request_type).current.nil?
    Maze::Server.list_for(request_type).next
  end
end

When('I run {string}') do |scenario_name|
  run_command("run_scenario", { scenario: scenario_name })
end

When('I load scenario {string}') do |scenario_name|
  run_command("load_scenario", { scenario: scenario_name })
end

When('I start bugsnag') do
  run_command("start_bugsnag", {})
end

When('I configure {string} to {string}') do |config_name, config_value|
  # Note: The method will usually be of the form "xyzWithParam:"
  run_command("configure_bugsnag", { path:config_name, value:config_value })
end

When('I run the loaded scenario') do
  run_command("run_loaded_scenario", {})
end

When('I invoke {string}') do |method_name|
  run_command("invoke_method", { method: method_name, arguments:[] })
end

When('I invoke {string} with parameter {string}') do |method_name, arg1|
  # Note: The method will usually be of the form "xyzWithParam:"
  run_command("invoke_method", { method:method_name, arguments:[arg1] })
end

When('I switch to the web browser for {int} second(s)') do |duration|
  run_command("background", { duration:duration.to_s })
end

When('I switch to the web browser') do
  run_command("background", { duration: "-1" })
end

def run_command(action, args)
  Maze::Server.commands.add({ action: action, args: args })
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

Then('no span field {string} equals {string}') do |key, value|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_span = spans.find { |span| span[key] and span[key] == value }
  Maze.check.nil(selected_span)
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

Then('a span named {string} is a child of span named {string}') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['traceId'] == second_span['traceId'] && first_span['parentSpanId'] == second_span['spanId'])
end

Then('a span named {string} started before a span named {string}') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['startTimeUnixNano'].to_i < second_span['startTimeUnixNano'].to_i)
end

When('I wait for exactly {int} span(s)') do |span_count|
  assert_received_exactly_spans span_count, Maze::Server.list_for('traces')
end

def assert_received_exactly_spans(span_count, list)
  timeout = Maze.config.receive_requests_wait
  wait = Maze::Wait.new(timeout: timeout)

  received = wait.until { spans_from_request_list(list).size == span_count }
  received_count = spans_from_request_list(list).size

  unless received
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

  wait = Maze::Wait.new(timeout: 5)

  Maze.check.operator(span_count, :==, received_count, "#{received_count} spans received")

  Maze::Schemas::Validator.verify_against_schema(list, 'trace')
  Maze::Schemas::Validator.validate_payload_elements(list, 'trace')
end

Then('a span double attribute {string} equals {float}') do |attribute, value|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  selected_attributes = selected_attributes.map { |a| a['value']['doubleValue'] == value }
  Maze.check.false(selected_attributes.empty?)
end
