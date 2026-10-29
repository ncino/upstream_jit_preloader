require "jit_preloader"

expected = ENV.fetch("AR_SERIES")
versions = [ActiveRecord::VERSION::STRING, ActiveSupport::VERSION::STRING]
abort "Expected ActiveRecord and ActiveSupport #{expected}, got #{versions.join(', ')}" unless versions.all? { |version| version.start_with?("#{expected}.") }
puts "Ruby #{RUBY_VERSION}; ActiveRecord #{versions.first}; ActiveSupport #{versions.last}; jit_preloader #{JitPreloader::VERSION}"
