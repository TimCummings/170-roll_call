# Rakefile

task default: %w[test]

task :test do
  test_path = File.expand_path('../test', __FILE__)
  test_files = Dir.glob(test_path + '/*_test.rb')
  test_files.each { |test_file| ruby test_file }
end
