# Fix for "conflicting chdir during another chdir block" in vite_ruby
# ViteRuby::Config#within_root uses Dir.chdir without a Mutex, causing
# race conditions when Puma serves concurrent requests with multiple threads.
if defined?(ViteRuby)
  VITE_RUBY_CHDIR_MUTEX = Mutex.new

  ViteRuby::Config.prepend(Module.new do
    def within_root(&block)
      VITE_RUBY_CHDIR_MUTEX.synchronize { super }
    end
  end)
end
