# frozen_string_literal: true

Maze.hooks.after do |scenario|
  folder1 = File.join(Dir.pwd, 'maze_output')
  folder2 = scenario.failed? ? 'failed' : 'passed'
  folder3 = scenario.name.gsub(/[:"& ]/, '_').gsub(/_+/, '_')

  path = File.join(folder1, folder2, folder3)

  case Maze::Helper.get_current_platform
  when 'ios'
    # get_log can be slow (1 or 2 seconds) on device farms
    if scenario.failed? || Maze.config.farm == :local
      FileUtils.makedirs(path)
      File.open(File.join(path, 'syslog.log'), 'wb') do |file|
        Maze.driver.get_log('syslog').each { |entry| file.puts entry.message }
      end
    end
  end
end
