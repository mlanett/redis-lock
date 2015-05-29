require File.expand_path('../lib/redis-lock/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Lanett", "Ravil Bayramgalin", "Jamie Cobbett", "Jonathan Hyman", "Alexander Lang"]
  gem.email         = ["mark.lanett@gmail.com"]
  gem.description   = %q{Pessimistic locking using Redis}
  gem.summary       = %q{Pessimistic locking using Redis}
  gem.homepage      = ""

  gem.files         = Dir.glob("lib/**/*.rb")
  gem.test_files    = Dir.glob("{test,spec}/**/*.rb")
  gem.name          = "mlanett-redis-lock"
  gem.require_paths = ["lib"]
  gem.version       = Redis::Lock::VERSION

  gem.add_dependency 'redis', '~> 3.0'
end
