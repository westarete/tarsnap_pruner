module TarsnapPruner

  # An instance of this class represents a single tarsnap backup.
  #
  # We expect the name of each archive to contain an iso8601 date that
  # represents the date that the backup was taken.
  class Scheduler

    def initialize(archives, daily_boundary=182, weekly_boundary=730)
      @archives = archives
      @daily_boundary = daily_boundary
      @weekly_boundary = weekly_boundary
    end

    def knowns
      @archives.select(&:date)
    end

    def unknowns
      @archives.reject(&:date)
    end

    def dailies
      []
    end

    def weeklies
      []
    end

    def monthlies
      []
    end

    def weeklies_to_keep
      []
    end

    def weeklies_to_prune
      []
    end

    def monthlies_to_keep
      []
    end

    def monthlies_to_prune
      []
    end

    def archives_to_prune
      unknowns
    end

  end

end
