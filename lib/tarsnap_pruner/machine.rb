module TarsnapPruner

  # An instance of this class represents one machine that's being backed up.
  class Machine

    def self.key_files
      Dir.glob(File.join(ENV['KEY_DIRECTORY'], '*.key')).sort
    end

    def self.all
      key_files.map { |f| new(f) }
    end

    def initialize(key_file, tarsnap=nil)
      @key_file = key_file
      @tarsnap = tarsnap || Tarsnap.new(@key_file)
    end

    attr_reader :key_file

    def hostname
      key_file =~ /tarsnap-(.*)\.key$/ ? $1 : 'unknown'
    end

    def archives
      @tarsnap.list_archives.split.sort.map { |name| Archive.new(name) }
    end

    def delete(archives_to_delete)
      if archives_to_delete.any?
        Dir.mktmpdir("cache-", ENV['CACHES_DIRECTORY']) do |cache_directory|
          # fsck so that we have an up-to-date cache (required for pruning). This
          # means that each machine will have to fsck again, but there's apparently
          # no way around it.
          # Ref: http://mail.tarsnap.com/tarsnap-users/msg00512.html
          @tarsnap.fsck(cache_directory)
          archives_to_delete.each do |archive|
            @tarsnap.delete(archive, cache_directory)
          end
        end
      end
    end

  end

end