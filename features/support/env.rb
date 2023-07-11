def invoke_command(method_name)
  Maze::Server.commands.add({ action: "invoke_method", args: [method_name] })
  Maze.driver.click_element :execute_command
  # Ensure fixture has read the command
  count = 100
  sleep 0.1 until Maze::Server.commands.remaining.empty? || (count -= 1) < 1
  raise 'Test fixture did not GET /command' unless Maze::Server.commands.remaining.empty?
end

Maze.hooks.after do |_scenario|
  invoke_command 'clearPersistentData'
end
