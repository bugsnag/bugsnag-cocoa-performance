# frozen_string_literal: true

# vim: set ft=ruby

def framework_size
  old_binary = 'DerivedData.old/Build/Products/Release-iphoneos/BugsnagPerformance.framework/BugsnagPerformance'
  new_binary = 'DerivedData.new/Build/Products/Release-iphoneos/BugsnagPerformance.framework/BugsnagPerformance'

  markdown <<~MARKDOWN
    ```
    #{`bloaty #{new_binary} -- #{old_binary}`.chomp}
    ```
  MARKDOWN
end

framework_size
