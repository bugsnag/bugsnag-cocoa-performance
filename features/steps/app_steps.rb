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

Before('@skip') do |_scenario|
  skip_this_scenario("Skipping scenario")
end

Then('I discard every {request_type}') do |request_type|
  until Maze::Server.list_for(request_type).current.nil?
    Maze::Server.list_for(request_type).next
  end
end

When('I run {string}') do |scenario_name|
  run_command("run_scenario", { scenario: scenario_name })
end

When('I run {string} configured as {string}') do |suite_name, args|
  run_command("run_suite", { suite: suite_name, arguments: args})
end

When('I load scenario {string}') do |scenario_name|
  run_command("load_scenario", { scenario: scenario_name })
end

When('I start bugsnag') do
  run_command("start_bugsnag", {})
end

When('I configure bugsnag {string} to {string}') do |config_name, config_value|
  run_command("configure_bugsnag", { path:config_name, value:config_value })
end

When('I configure scenario {string} to {string}') do |config_name, config_value|
  run_command("configure_scenario", { path:config_name, value:config_value })
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

Then('every span attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['attributes'].find { |a| a['key'] == attribute } }
end

Then('every span bool attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['attributes'].find { |a| a['key'] == attribute } }
end

Then('every span string attribute {string} does not exist') do |attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  spans.map { |span| Maze.check.nil span['attributes'].find { |a| a['key'] == attribute } }
end

Then('every span integer attribute {string} does not exist') do |attribute|
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

Then('the span named {string} integer attribute {string} is greater than {int}') do |spanName, attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  span = spans.find { |span| span['name'] == spanName }
  selected_attribute = span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') }
  Maze.check.true(selected_attribute['value']['intValue'].to_f > expected)
end

Then('the span named {string} integer attribute {string} exists') do |spanName, attribute|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| span['name'] == spanName && a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  Maze.check.false(selected_attributes.empty?)
end

Then('a span integer attribute {string} is greater than {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['intValue'].to_i > expected }
  Maze.check.false(attribute_values.empty?)
end

Then('a span integer attribute {string} equals {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['intValue'].to_i == expected }
  Maze.check.false(attribute_values.empty?)
end

Then('a span integer attribute {string} is less than {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['intValue'].to_i < expected }
  Maze.check.false(attribute_values.empty?)
end

Then('the span named {string} float attribute {string} is greater than {float}') do |spanName, attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  span = spans.find { |span| span['name'] == spanName }
  selected_attribute = span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') }
  Maze.check.true(selected_attribute['value']['doubleValue'].to_f > expected)
end

Then('a span float attribute {string} is greater than {float}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['doubleValue'].to_f > expected }
  Maze.check.false(attribute_values.empty?)
end

Then('every span float attribute {string} is greater than {float}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['doubleValue'].to_f > expected }
  Maze.check.not_includes attribute_values, false
end

Then('a span float attribute {string} equals {float}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['doubleValue'].to_f == expected }
  Maze.check.false(attribute_values.empty?)
end

Then('a span float attribute {string} is less than {float}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  attribute_values = selected_attributes.map { |a| a['value']['doubleValue'].to_f < expected }
  Maze.check.false(attribute_values.empty?)
end



Then('a span array attribute {string} contains the string value {string} at index {int}') do |attribute, expected, index|
  value = get_array_value_at_index(attribute, index, 'stringValue')
  Maze.check.true(value == expected)
end

Then('a span array attribute {string} contains the integer value {int} at index {int}') do |attribute, expected, index|
  value = get_array_value_at_index(attribute, index, 'intValue')
  Maze.check.true(value.to_i == expected)
end

Then('a span array attribute {string} contains the float value {float} at index {int}') do |attribute, expected, index|
  value = get_array_value_at_index(attribute, index, 'doubleValue')
  Maze.check.true(value == expected)
end

Then('a span array attribute {string} contains the value true at index {int}') do |attribute, index|
  value = get_array_value_at_index(attribute, index, 'boolValue')
  Maze.check.true(value == true)
end

Then('a span array attribute {string} contains the value false at index {int}') do |attribute, index|
  value = get_array_value_at_index(attribute, index, 'boolValue')
  Maze.check.true(value == false)
end

Then('a span array attribute {string} contains no value at index {int}') do |attribute, index|
  array = get_array_attribute_contents(attribute)
  Maze.check.true(array.length() <= index)
end

def get_array_value_at_index(attribute, index, type)
  array = get_array_attribute_contents(attribute)
  Maze.check.true(array.length() > index)
  value = array[index]
  Maze.check.true(value.has_key?(type))
  return value[type]
end

def get_array_attribute_contents(attribute)
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) &&
                                                                         a['value'].has_key?('arrayValue') &&
                                                                         a['value']['arrayValue'].has_key?('values') } }.compact
  array_attributes = selected_attributes.map { |a| a['value']['arrayValue']['values'] }
  Maze.check.false(array_attributes.empty?)
  return array_attributes[0]
end

def get_array_attribute_contents_named(spanName, attribute)
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  span = spans.find { |span| span['name'] == spanName }
  selected_attribute = span['attributes'].find { |a| a['key'].eql?(attribute) &&
                                                     a['value'].has_key?('arrayValue') &&
                                                     a['value']['arrayValue'].has_key?('values') }
  array_attributes = selected_attribute['value']['arrayValue']['values']
  return array_attributes
end

Then('the span named {string} array attribute {string} is not empty') do |name, attribute|
  array_contents = get_array_attribute_contents_named(name, attribute)
  Maze.check.false(array_contents.empty?)
end

Then('a span array attribute {string} is empty') do |attribute|
  array_contents = get_array_attribute_contents(attribute)
  Maze.check.true(array_contents.empty?)
end

Then('a span array attribute {string} contains {int} elements') do |attribute, count|
  array_contents = get_array_attribute_contents(attribute)
  Maze.check.true(array_contents.length() == count)
end

Then('a span array attribute {string} contains from {int} to {int} elements') do |attribute, count_low, count_high|
  array_contents = get_array_attribute_contents(attribute)
  Maze.check.true(array_contents.length() >= count_low && array_contents.length() <= count_high)
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

Then('a span named {string} ended before a span named {string} started') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['endTimeUnixNano'].to_i < second_span['startTimeUnixNano'].to_i)
end

Then('a span named {string} ended at the same time as a span named {string}') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['endTimeUnixNano'].to_i == second_span['endTimeUnixNano'].to_i)
end

Then('a span named {string} ended before a span named {string}') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['endTimeUnixNano'].to_i < second_span['endTimeUnixNano'].to_i)
end

Then('a span named {string} ended after a span named {string}') do |name1, name2|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  first_span = spans.find { |span| span['name'] == name1 }
  second_span = spans.find { |span| span['name'] == name2 }
  Maze.check.true(first_span['endTimeUnixNano'].to_i > second_span['endTimeUnixNano'].to_i)
end

Then('a span named {string} duration is equal or less than {float}') do |name, maxDuration|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  span = spans.find { |span| span['name'] == name }
  duration = (span['endTimeUnixNano'].to_i - span['startTimeUnixNano'].to_i)/1000000000
  Maze.check.true(duration <= maxDuration)
end

Then('a span named {string} duration is equal or greater than {float}') do |name, minDuration|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  span = spans.find { |span| span['name'] == name }
  duration = (span['endTimeUnixNano'].to_i - span['startTimeUnixNano'].to_i)/1000000000
  Maze.check.true(duration >= minDuration)
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
end

Then('a span double attribute {string} equals {float}') do |attribute, value|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  selected_attributes = selected_attributes.map { |a| a['value']['doubleValue'] == value }
  Maze.check.false(selected_attributes.empty?)
end

Then('the span named {string} is the parent of every span named {string}') do |span1name, span2name|
  
  spans = spans_from_request_list(Maze::Server.list_for("traces"))

  parentSpan = spans.find_all { |span| span['name'].eql?(span1name) }.first

  childSpans2 = spans.find_all { |span| span['name'].eql?(span2name) }

  childSpans2.map { |span| Maze.check.true(parentSpan['spanId'] == span['parentSpanId']) }
end

def spans_from_request_list(list)
  list.remaining
      .flat_map { |req| req[:body]['resourceSpans'] }
      .flat_map { |r| r['scopeSpans'] }
      .flat_map { |s| s['spans'] }
      .select { |s| !s.nil? }
end

Then('the difference between "Bugsnag-Sent-At" of first and last request is at most {int} seconds') do |max_diff_s|
  list = Maze::Server.list_for("traces")
  requestListSize = list.size_all
  req1 = list.get(0)[:request]
  req2 = list.get(requestListSize - 1)[:request]
  req1sec = 100000
  req2sec = 100000

  # DateTime.parse throws ArgumentError if it can't parse the string
  if dt = DateTime.iso8601(req1["Bugsnag-Sent-At"]) rescue false
    req1sec = dt.hour * 3600 + dt.min * 60 + dt.second
  end
  if dt = DateTime.iso8601(req2["Bugsnag-Sent-At"]) rescue false
    req2sec = dt.hour * 3600 + dt.min * 60 + dt.second
  end
  diff = (req1sec - req2sec).abs
  Maze.check.true(diff <= max_diff_s)
end

When("I relaunch the app after shutdown") do
  max_attempts = 20
  attempts = 0
  manager = Maze::Api::Appium::AppManager.new
  state = manager.state
  until (attempts >= max_attempts) || state == :not_running
    attempts += 1
    state = manager.state
    sleep 0.5
  end
  $logger.warn "App state #{state} instead of not_running after 10s" unless state == :not_running

  manager.activate
end
