guard "rspec" do
  watch(%r{^lib/redis-lock\.rb$}) { "spec" }
  watch(%r{^spec/.+_spec\.rb$})
  watch("spec/helper.rb")         { "spec" }
  watch(%r{^spec/support/.+\.rb}) { "spec" }
end
