require 'logger'

unless defined?(::Logger)
  ::Logger = Class.new do
    def initialize(*args); end
    def level=(level); end
    def add(*args); end
    def debug(*args); end
    def info(*args); end
    def warn(*args); end
    def error(*args); end
    def fatal(*args); end
  end
end

module ActiveSupport
  module LoggerThreadSafeLevel
    const_set(:Logger, ::Logger) unless const_defined?(:Logger)
  end
end
