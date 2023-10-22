begin
  require 'rspec/core/rake_task'

  desc 'Run API specs test in spec/requests and generate documentation'
  RSpec::Core::RakeTask.new('spec:integration', :spec_file) do |t, t_args|
    t.pattern = t_args[:spec_file] || 'spec/requests/**/*_spec.rb'
    t.rspec_opts = ['--format RspecApiDocumentation::ApiFormatter']
  end
rescue LoadError => e
end