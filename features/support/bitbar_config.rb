# frozen_string_literal: true

Before('@resource_aggregation') do
  next unless Maze.config.farm == :bb

  @original_receive_requests_wait = Maze.config.receive_requests_wait
  Maze.config.receive_requests_wait = 60

  traces = Maze::Server.list_for('traces')
  traces.next until traces.current.nil?
end

After('@resource_aggregation') do
  next unless Maze.config.farm == :bb
  next unless @original_receive_requests_wait

  Maze.config.receive_requests_wait = @original_receive_requests_wait
end
