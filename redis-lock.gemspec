# -*- encoding: utf-8 -*-
require File.expand_path('../lib/redis-lock/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Lanett"]
  gem.email         = ["mark.lanett@gmail.com"]
  gem.description   = %q{Pessimistic locking using Redis}
  gem.summary       = %q{Pessimistic locking using Redis}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "mlanett-redis-lock"
  gem.require_paths = ["lib"]
  gem.version       = Redis::Lock::VERSION

  gem.add_dependency "redis"
end
