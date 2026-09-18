# frozen_string_literal: true

Maze.hooks.after do |scenario|
  folder1 = File.join(Dir.pwd, 'maze_output')
  folder2 = scenario.failed? ? 'failed' : 'passed'
  folder3 = scenario.name.gsub(/[:"& ]/, '_').gsub(/_+/, '_')
  path = File.join(folder1, folder2, folder3)
  case Maze::Helper.get_current_platform
  when 'ios'
    if scenario.failed? || Maze.config.farm == :local
      FileUtils.makedirs(path)
      File.open(File.join(path, 'syslog.log'), 'wb') do |file|
        begin
          driver = Maze.driver.respond_to?(:driver) ? Maze.driver.driver : Maze.driver
          driver.manage.logs.get('syslog').each do |entry|
                file.puts entry.message
          end
        rescue StandardError => e
          file.puts "Failed to retrieve syslog: #{e.message}"
        end
      end
    end
  end
end
