module TarsnapPruner

  # A class to encapsulate invoking the command-line tarsnap commands.
  class Tarsnap

    def initialize(key_file)
      @key_file = key_file
    end

    def list_archives
      `#{tarsnap} --list-archives --keyfile #{@key_file}`
    end

    def fsck(cache_directory)
      system "#{tarsnap} --fsck --keyfile #{@key_file} --cachedir #{cache_directory} > /dev/null"
    end

    def delete(archive, cache_directory)
      system "#{tarsnap} -d --keyfile #{@key_file} --cachedir #{cache_directory} -f #{archive.name} > /dev/null"
    end

    private

    def tarsnap
      ENV['TARSNAP_COMMAND']
    end

  end

end
