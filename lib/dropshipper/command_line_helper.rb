module Dropshipper
  class CommandLineHelper
    def self.get_input
      $stdin.gets.chomp
    end

    # http://andowebsit.es/blog/noteslog.com/post/how-to-run-rake-tasks-programmatically/
    def self.capture_stderr
      previous = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = previous
    end

    def self.capture_stdout
      previous = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = previous
    end
  end
end
