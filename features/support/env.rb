require 'simplecov'
SimpleCov.start
SimpleCov.root(File.join(File.expand_path(__dir__), '..'))

require 'aruba/cucumber'

# If you use this with Aruba, aruba will use <project_root>/tmp/aruba/home.
# Aruba then provides you with some nice cucumber steps to verify files are
# created, exist, etc.
Before do
  set_env 'HOME', File.expand_path(File.join(current_dir, 'home'))
  FileUtils.mkdir_p ENV['HOME']
end
