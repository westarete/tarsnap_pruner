require 'date'

module TarsnapPruner

  # An instance of this class represents a single tarsnap backup.
  #
  # We expect the name of each archive to contain an iso8601 date that
  # represents the date that the backup was taken.
  class Archive

    # Expects the name of the archive, as given to tarsnap. It should contain
    # an iso8601 date (e.g. 2015-05-15) that represents when the backup was
    # taken.
    def initialize(name)
      @name = name
    end

    attr_reader :name

    # Return a Ruby Date object for the backup's date, or nil if one could not
    # be discerned from the archive name.
    def date
      name =~ /.*(\d{4}-\d{2}-\d{2})/ ? Date.parse($1) : nil
    end

    # The number of days that have elapsed since the backup date.
    def elapsed
      date ? Date.today - date : nil
    end

  end
end
