require "bundler/gem_tasks"
require "rake/testtask"
require "rake/extensiontask"

task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"].exclude(/docs_test/)
end

Rake::TestTask.new("test:docs") do |t|
  t.libs << "test"
  t.pattern = "test/docs_test.rb"
end

Rake::ExtensionTask.new("polars") do |ext|
  ext.lib_dir = "lib/polars"
end

task :remove_ext do
  path = "lib/polars/polars.bundle"
  File.unlink(path) if File.exist?(path)
end

Rake::Task["build"].enhance [:remove_ext]
