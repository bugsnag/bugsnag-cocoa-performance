def invoke_command(action, args)
  $logger.info "#{Maze::Server.commands.remaining.size} commands before"
  Maze::Server.commands.add({ action: action, args: args })
  Maze.driver.click_element :execute_command
  # Ensure fixture has read the command
  count = 100
  sleep 0.1 until Maze::Server.commands.remaining.empty? || (count -= 1) < 1
  $logger.info "#{Maze::Server.commands.remaining.size} commands after"
  raise 'Test fixture did not GET /command' unless Maze::Server.commands.remaining.empty?
end

Maze.hooks.after do |_scenario|
  $logger.info 'Issuing clearPersistentData command'
  invoke_command('invoke_method', ['clearPersistentData'])
end
