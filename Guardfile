guard :rspec, :version => 2, :cli => "--color --drb -r rspec/instafail -f RSpec::Instafail", :bundler => false, :all_after_pass => false, :all_on_start => false, :keep_failed => false do
  watch('spec/spec_helper.rb') { "spec" }
  watch(%r{^lib/(.+)\.rb})     { |m| "spec/lib/#{m[1]}_spec.rb" }
end
