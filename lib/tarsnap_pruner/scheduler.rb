module TarsnapPruner

  class Scheduler

    def initialize(archives, daily_boundary=90, weekly_boundary=365)
      @archives = archives.sort_by(&:date)
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
      knowns.select { |a| a.elapsed < @daily_boundary }
    end

    def weeklies
      knowns.select { |a| a.elapsed >= @daily_boundary && a.elapsed < @weekly_boundary }
    end

    def monthlies
      knowns.select { |a| a.elapsed >= @weekly_boundary }
    end

    def weeklies_to_keep
      weeklies.group_by { |a| [a.date.year, a.date.cweek] }.values.map(&:last)
    end

    def weeklies_to_prune
      weeklies - weeklies_to_keep
    end

    def monthlies_to_keep
      monthlies.group_by { |a| a.date.month }.values.map(&:last)
    end

    def monthlies_to_prune
      monthlies - monthlies_to_keep
    end

    def archives_to_prune
      unknowns + monthlies_to_prune + weeklies_to_prune
    end

  end

end
