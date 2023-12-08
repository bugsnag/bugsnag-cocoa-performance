# frozen_string_literal: true

# vim: set ft=ruby

def framework_size
  def _(number) # Formats a number with thousands separated by ','
    number.to_s.reverse.scan(/.{1,3}/).join(',').reverse
  end

  old_binary = 'DerivedData.old/Build/Products/Release-iphoneos/BugsnagPerformance.framework/BugsnagPerformance'
  new_binary = 'DerivedData.new/Build/Products/Release-iphoneos/BugsnagPerformance.framework/BugsnagPerformance'

  size_after = File.size(new_binary)
  size_before = File.size(old_binary)

  case true
  when size_after == size_before
    markdown("**`BugsnagPerformance.framework`** binary size did not change - #{_(size_after)} bytes")
  when size_after < size_before
    markdown("**`BugsnagPerformance.framework`** binary size decreased by #{_(size_before - size_after)} bytes from #{_(size_before)} to #{_(size_after)} :tada:")
  when size_after > size_before
    markdown("**`BugsnagPerformance.framework`** binary size increased by #{_(size_after - size_before)} bytes from #{_(size_before)} to #{_(size_after)}")
  end

  markdown <<~MARKDOWN
    ```
    #{`bloaty #{new_binary} -- #{old_binary}`.chomp}
    ```
  MARKDOWN
end

framework_size
