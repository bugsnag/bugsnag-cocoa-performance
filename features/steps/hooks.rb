# frozen_string_literal: true

Maze.hooks.after do |scenario|
  folder1 = File.join(Dir.pwd, 'maze_output')
  folder2 = scenario.failed? ? 'failed' : 'passed'
  folder3 = scenario.name.gsub(/[:"& ]/, '_').gsub(/_+/, '_')

  path = File.join(folder1, folder2, folder3)

  case Maze::Helper.get_current_platform
  when 'ios'
    # get_logs can be slow (1 or 2 seconds) on device farms
    if scenario.failed? || Maze.config.farm == :local
      begin
        manager = Maze::Api::Appium::DeviceManager.new
        # `get_log` was renamed to `get_logs` in Maze Runner 11.
        entries = if manager.respond_to?(:get_logs)
                    manager.get_logs('syslog')
                  else
                    manager.get_log('syslog')
                  end
        FileUtils.makedirs(path)
        File.open(File.join(path, 'syslog.log'), 'wb') do |file|
          entries.each { |entry| file.puts entry.message }
        end
      rescue StandardError => e
        # Never let log collection mask the actual scenario result.
        $logger.warn "Unable to capture device syslog: #{e.class}: #{e.message}"
      end
    end
  end
end
