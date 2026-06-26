# features/steps/span_integer_steps.rb
# Custom steps using the same Maze::Server API as app_steps.rb

# Integer attribute > value
Then('span integer attribute {string} should be greater than {int}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('intValue') } }.compact
  Maze.check.false(selected_attributes.empty?, "No span found with attribute '#{attribute}'")
  selected_attributes.each do |a|
    val = a['value']['intValue'].to_i
    Maze.check.true(val > expected, "Expected #{attribute} (#{val}) > #{expected}")
  end
end

# Float attribute > value
Then('span float attribute {string} should be greater than {float}') do |attribute, expected|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  selected_attributes = spans.map { |span| span['attributes'].find { |a| a['key'].eql?(attribute) && a['value'].has_key?('doubleValue') } }.compact
  Maze.check.false(selected_attributes.empty?, "No span found with attribute '#{attribute}'")
  selected_attributes.each do |a|
    val = a['value']['doubleValue'].to_f
    Maze.check.true(val > expected, "Expected #{attribute} (#{val}) > #{expected}")
  end
end

# Cross-attribute comparison: integer A <= integer B
Then('a span integer attribute {string} is less than or equal to span integer attribute {string}') do |attr_a, attr_b|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  found = false
  spans.each do |span|
    attrs = span['attributes'] || []
    val_a = attrs.find { |a| a['key'] == attr_a }&.dig('value', 'intValue')&.to_i
    val_b = attrs.find { |a| a['key'] == attr_b }&.dig('value', 'intValue')&.to_i
    next if val_a.nil? || val_b.nil?
    Maze.check.true(val_a <= val_b, "Expected #{attr_a} (#{val_a}) <= #{attr_b} (#{val_b})")
    found = true
  end
  raise "No span found with both '#{attr_a}' and '#{attr_b}'" unless found
end

# Cross-attribute comparison: float A <= float B
Then('a span float attribute {string} is less than or equal to span float attribute {string}') do |attr_a, attr_b|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  found = false
  spans.each do |span|
    attrs = span['attributes'] || []
    val_a = attrs.find { |a| a['key'] == attr_a }&.dig('value', 'doubleValue')&.to_f
    val_b = attrs.find { |a| a['key'] == attr_b }&.dig('value', 'doubleValue')&.to_f
    next if val_a.nil? || val_b.nil?
    Maze.check.true(val_a <= val_b, "Expected #{attr_a} (#{val_a}) <= #{attr_b} (#{val_b})")
    found = true
  end
  raise "No span found with both '#{attr_a}' and '#{attr_b}'" unless found
end

# Cross-attribute equality: integer A == integer B
Then('a span integer attribute {string} equals span integer attribute {string}') do |attr_a, attr_b|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  found = false
  spans.each do |span|
    attrs = span['attributes'] || []
    val_a = attrs.find { |a| a['key'] == attr_a }&.dig('value', 'intValue')&.to_i
    val_b = attrs.find { |a| a['key'] == attr_b }&.dig('value', 'intValue')&.to_i
    next if val_a.nil? || val_b.nil?
    Maze.check.true(val_a == val_b, "Expected #{attr_a} (#{val_a}) == #{attr_b} (#{val_b})")
    found = true
  end
  raise "No span found with both '#{attr_a}' and '#{attr_b}'" unless found
end

# Cross-attribute equality: float A == float B
Then('a span float attribute {string} equals span float attribute {string}') do |attr_a, attr_b|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  found = false
  spans.each do |span|
    attrs = span['attributes'] || []
    val_a = attrs.find { |a| a['key'] == attr_a }&.dig('value', 'doubleValue')&.to_f
    val_b = attrs.find { |a| a['key'] == attr_b }&.dig('value', 'doubleValue')&.to_f
    next if val_a.nil? || val_b.nil?
    Maze.check.true(val_a == val_b, "Expected #{attr_a} (#{val_a}) == #{attr_b} (#{val_b})")
    found = true
  end
  raise "No span found with both '#{attr_a}' and '#{attr_b}'" unless found
end

Then('span float attribute {string} should be less than {float}') do |attribute, max_val|
  spans = spans_from_request_list(Maze::Server.list_for('traces'))
  found = false
  spans.each do |span|
    attrs = span['attributes'] || []
    attr = attrs.find { |a| a['key'] == attribute }
    next unless attr
    val = attr['value']['doubleValue'].to_f
    found = true
    Maze.check.true(val < max_val, "Expected #{attribute} (#{val}) < #{max_val}.")
  end
  Maze.check.true(found, "No span found with attribute '#{attribute}'.")
end
