module TarsnapPruner

  # A replacement for TarsnapCommand during tests
  class MockTarsnapCommand

    def initialize(key_file)
      @key_file = key_file
    end

    def list_archives
      %w{
        hostname-2015-05-12
        hostname-2015-05-13
        hostname-2015-05-14
      }.join("\n") + "\n"
    end

    def fsck(cache_directory)
    end

    def delete(archive, cache_directory)
    end

  end

end
