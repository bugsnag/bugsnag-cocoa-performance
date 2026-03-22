# frozen_string_literal: true

Given('the app is configured with filesystem IO disabled') do
  run_command('configure_bugsnag', { path: 'disableFilesystemIO', value: 'true' })
end

When('the retry queue is initialized') do
  run_command('run_scenario', { scenario: 'DisabledFilesystemIOScenario' })
end

When('the queue operations preStartSetup, sweep, list, get, add, and remove are called') do
  run_command('invoke_method', { method: 'queuePreStartSetup', arguments: [] })
  run_command('invoke_method', { method: 'queueSweep', arguments: [] })
  run_command('invoke_method', { method: 'queueList', arguments: [] })
  run_command('invoke_method', { method: 'queueGet', arguments: [] })
  run_command('invoke_method', { method: 'queueAdd', arguments: [] })
  run_command('invoke_method', { method: 'queueRemove', arguments: [] })
end

Then('the filesystem error callback should be called once') do
  result = run_command('invoke_method', { method: 'get_filesystem_error_call_count', arguments: [] })
  Maze.check.true(result == 1)
end

Then('the file at the queue path should not exist') do
  result = run_command('invoke_method', { method: 'file_exists_at_queue_path', arguments: [] })
  Maze.check.false(result)
end
