require 'spec_helper'

describe TarsnapPruner::Scheduler do

  # We freeze all of the Scheduler tests to a static date, so that we can
  # use concrete examples for our data, as opposed to having to do relative
  # calculations to the current time.
  let(:today) { Date.new(2015,12,31) }
  around do |example|
    Timecop.freeze(today)
    example.run
    Timecop.return
  end

  # Keep daily backups back to 14 days, weeklies back to 60 days, and
  # monthlies after that.
  let(:daily_boundary) { 10 }
  let(:weekly_boundary) { 30 }
  let(:scheduler) { TarsnapPruner::Scheduler.new(archives, daily_boundary, weekly_boundary) }

  context "given an empty array of archives" do
    let(:archives) { [] }
    describe 'each collection method' do
      it "returns an empty array" do
        expect(scheduler.knowns).to be_empty
        expect(scheduler.unknowns).to be_empty
        expect(scheduler.dailies).to be_empty
        expect(scheduler.weeklies).to be_empty
        expect(scheduler.monthlies).to be_empty
        expect(scheduler.weeklies_to_keep).to be_empty
        expect(scheduler.weeklies_to_prune).to be_empty
        expect(scheduler.monthlies_to_keep).to be_empty
        expect(scheduler.monthlies_to_prune).to be_empty
        expect(scheduler.archives_to_prune).to be_empty
      end
    end
  end

  context "given some archives that don't contain a date" do
    let(:archives) do
      %w{
        hostname-1
        hostname-2
        hostname-3
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "marks them as unknown" do
      expect(scheduler.unknowns).to eq archives
    end
    it "includes them in the archives to prune" do
      archives.each do |a|
        expect(scheduler.archives_to_prune).to include a
      end
    end
    it "doesn't include them in any other collection" do
      archives.each do |a|
        expect(scheduler.knowns).to_not include a
        expect(scheduler.dailies).to_not include a
        expect(scheduler.weeklies).to_not include a
        expect(scheduler.monthlies).to_not include a
        expect(scheduler.weeklies_to_keep).to_not include a
        expect(scheduler.weeklies_to_prune).to_not include a
        expect(scheduler.monthlies_to_keep).to_not include a
        expect(scheduler.monthlies_to_prune).to_not include a
      end
    end
  end

  context "given some archives that do contain a date in ISO8601 format" do
    let(:archives) do
      %w{
        hostname-2015-01-15
        hostname-2015-02-15
        hostname-2015-03-15
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "marks them as known" do
      expect(scheduler.knowns).to eq archives
    end
  end

  context "given archives that only span the daily period" do
    let(:archives) do
      %w{
        hostname-2015-12-30
        hostname-2015-12-29
        hostname-2015-12-28
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "includes them in the knowns" do
      archives.each do |a|
        expect(scheduler.knowns).to include a
      end
    end
    it "includes them in the dailies" do
      archives.each do |a|
        expect(scheduler.dailies).to include a
      end
    end
    it "doesn't include them in any other collection" do
      archives.each do |a|
        expect(scheduler.unknowns).to_not include a
        expect(scheduler.weeklies).to_not include a
        expect(scheduler.monthlies).to_not include a
        expect(scheduler.weeklies_to_keep).to_not include a
        expect(scheduler.weeklies_to_prune).to_not include a
        expect(scheduler.monthlies_to_keep).to_not include a
        expect(scheduler.monthlies_to_prune).to_not include a
        expect(scheduler.archives_to_prune).to_not include a
      end
    end
  end

  context "given daily archives that go back through all periods" do
    let(:archives) do
      90.downto(0).collect do |i|
        TarsnapPruner::Archive.new("hostname-#{today-i}")
      end
    end
    it "knows all of them" do
      archives.each do |a|
        expect(scheduler.knowns).to include a
        expect(scheduler.unknowns).to_not include a
      end
    end
    it "sets the dailies" do
      expect(scheduler.dailies.map(&:date)).to eq (Date.new(2015,12,22)..Date.new(2015,12,31)).to_a
    end
    it "sets the weeklies" do
      expect(scheduler.weeklies.map(&:date)).to eq (Date.new(2015,12,2)..Date.new(2015,12,21)).to_a
    end
    it "sets the monthlies" do
      expect(scheduler.monthlies.map(&:date)).to eq (Date.new(2015,10,2)..Date.new(2015,12,1)).to_a
    end
    it "keeps the weeklies that fall on the last day of each week" do
      expect(scheduler.weeklies_to_keep.map { |a| a.date.to_s }).to eq %w{
        2015-12-06
        2015-12-13
        2015-12-20
        2015-12-21
      }
    end
    let(:expected_weeklies_to_prune) {%w{
        2015-12-02
        2015-12-03
        2015-12-04
        2015-12-05

        2015-12-07
        2015-12-08
        2015-12-09
        2015-12-10
        2015-12-11
        2015-12-12

        2015-12-14
        2015-12-15
        2015-12-16
        2015-12-17
        2015-12-18
        2015-12-19
    }}
    it "prunes the rest of archives that fall within the weeklies period" do
      expect(scheduler.weeklies_to_prune.map { |a| a.date.to_s }).to eq expected_weeklies_to_prune
    end
    it "keeps the monthlies that fall on the last day of each month" do
      expect(scheduler.monthlies_to_keep.map { |a| a.date.to_s }).to eq %w{
        2015-10-31
        2015-11-30
        2015-12-01
      }
    end
    let(:expected_monthlies_to_prune) {%w{
        2015-10-02
        2015-10-03
        2015-10-04
        2015-10-05
        2015-10-06
        2015-10-07
        2015-10-08
        2015-10-09
        2015-10-10
        2015-10-11
        2015-10-12
        2015-10-13
        2015-10-14
        2015-10-15
        2015-10-16
        2015-10-17
        2015-10-18
        2015-10-19
        2015-10-20
        2015-10-21
        2015-10-22
        2015-10-23
        2015-10-24
        2015-10-25
        2015-10-26
        2015-10-27
        2015-10-28
        2015-10-29
        2015-10-30

        2015-11-01
        2015-11-02
        2015-11-03
        2015-11-04
        2015-11-05
        2015-11-06
        2015-11-07
        2015-11-08
        2015-11-09
        2015-11-10
        2015-11-11
        2015-11-12
        2015-11-13
        2015-11-14
        2015-11-15
        2015-11-16
        2015-11-17
        2015-11-18
        2015-11-19
        2015-11-20
        2015-11-21
        2015-11-22
        2015-11-23
        2015-11-24
        2015-11-25
        2015-11-26
        2015-11-27
        2015-11-28
        2015-11-29
    }}
    it "prunes the rest of archives that fall within the monthlies period" do
      expect(scheduler.monthlies_to_prune.map { |a| a.date.to_s }).to eq expected_monthlies_to_prune
    end
    it "returns the complete list of archives to prune" do
      expect(scheduler.archives_to_prune.map { |a| a.date.to_s }).to eq(expected_monthlies_to_prune + expected_weeklies_to_prune)
    end
  end

  context "given actual backups from centre foundation" do
    let(:daily_boundary) { 90 }
    let(:weekly_boundary) { 365 }
    let(:archives) do
      %w{
        centre-foundation-2015-07-01
        centre-foundation-2015-07-02
        centre-foundation-2015-07-03
        centre-foundation-2015-07-04
        centre-foundation-2015-07-05
        centre-foundation-2015-07-06
        centre-foundation-2015-07-07
        centre-foundation-2015-07-08
        centre-foundation-2015-07-09
        centre-foundation-2015-07-10
        centre-foundation-2015-07-11
        centre-foundation-2015-07-12
        centre-foundation-2015-07-13
        centre-foundation-2015-07-14
        centre-foundation-2015-07-15
        centre-foundation-2015-07-16
        centre-foundation-2015-07-17
        centre-foundation-2015-07-18
        centre-foundation-2015-07-19
        centre-foundation-2015-07-20
        centre-foundation-2015-07-21
        centre-foundation-2015-07-22
        centre-foundation-2015-07-23
        centre-foundation-2015-07-24
        centre-foundation-2015-07-25
        centre-foundation-2015-07-26
        centre-foundation-2015-07-27
        centre-foundation-2015-07-28
        centre-foundation-2015-07-29
        centre-foundation-2015-07-30
        centre-foundation-2015-07-31
        centre-foundation-2015-08-01
        centre-foundation-2015-08-02
        centre-foundation-2015-08-03
        centre-foundation-2015-08-04
        centre-foundation-2015-08-05
        centre-foundation-2015-08-06
        centre-foundation-2015-08-07
        centre-foundation-2015-08-08
        centre-foundation-2015-08-09
        centre-foundation-2015-08-10
        centre-foundation-2015-08-11
        centre-foundation-2015-08-12
        centre-foundation-2015-08-13
        centre-foundation-2015-08-14
        centre-foundation-2015-08-15
        centre-foundation-2015-08-16
        centre-foundation-2015-08-17
        centre-foundation-2015-08-18
        centre-foundation-2015-08-19
        centre-foundation-2015-08-20
        centre-foundation-2015-08-21
        centre-foundation-2015-08-22
        centre-foundation-2015-08-23
        centre-foundation-2015-08-24
        centre-foundation-2015-08-25
        centre-foundation-2015-08-26
        centre-foundation-2015-08-27
        centre-foundation-2015-08-28
        centre-foundation-2015-08-29
        centre-foundation-2015-08-30
        centre-foundation-2015-08-31
        centre-foundation-2015-09-01
        centre-foundation-2015-09-02
        centre-foundation-2015-09-03
        centre-foundation-2015-09-04
        centre-foundation-2015-09-05
        centre-foundation-2015-09-06
        centre-foundation-2015-09-07
        centre-foundation-2015-09-08
        centre-foundation-2015-09-09
        centre-foundation-2015-09-10
        centre-foundation-2015-09-11
        centre-foundation-2015-09-12
        centre-foundation-2015-09-13
        centre-foundation-2015-09-14
        centre-foundation-2015-09-15
        centre-foundation-2015-09-16
        centre-foundation-2015-09-17
        centre-foundation-2015-09-18
        centre-foundation-2015-09-19
        centre-foundation-2015-09-20
        centre-foundation-2015-09-21
        centre-foundation-2015-09-22
        centre-foundation-2015-09-23
        centre-foundation-2015-09-24
        centre-foundation-2015-09-25
        centre-foundation-2015-09-26
        centre-foundation-2015-09-27
        centre-foundation-2015-09-28
        centre-foundation-2015-09-29
        centre-foundation-2015-09-30
        centre-foundation-2015-10-01
        centre-foundation-2015-10-02
        centre-foundation-2015-10-03
        centre-foundation-2015-10-04
        centre-foundation-2015-10-05
        centre-foundation-2015-10-06
        centre-foundation-2015-10-07
        centre-foundation-2015-10-08
        centre-foundation-2015-10-09
        centre-foundation-2015-10-10
        centre-foundation-2015-10-11
        centre-foundation-2015-10-12
        centre-foundation-2015-10-13
        centre-foundation-2015-10-14
        centre-foundation-2015-10-15
        centre-foundation-2015-10-16
        centre-foundation-2015-10-17
        centre-foundation-2015-10-18
        centre-foundation-2015-10-19
        centre-foundation-2015-10-20
        centre-foundation-2015-10-21
        centre-foundation-2015-10-22
        centre-foundation-2015-10-23
        centre-foundation-2015-10-24
        centre-foundation-2015-10-25
        centre-foundation-2015-10-26
        centre-foundation-2015-10-27
        centre-foundation-2015-10-28
        centre-foundation-2015-10-29
        centre-foundation-2015-10-30
        centre-foundation-2015-10-31
        centre-foundation-2015-11-01
        centre-foundation-2015-11-02
        centre-foundation-2015-11-03
        centre-foundation-2015-11-04
        centre-foundation-2015-11-05
        centre-foundation-2015-11-06
        centre-foundation-2015-11-07
        centre-foundation-2015-11-08
        centre-foundation-2015-11-09
        centre-foundation-2015-11-10
        centre-foundation-2015-11-11
        centre-foundation-2015-11-12
        centre-foundation-2015-11-13
        centre-foundation-2015-11-14
        centre-foundation-2015-11-15
        centre-foundation-2015-11-16
        centre-foundation-2015-11-17
        centre-foundation-2015-11-18
        centre-foundation-2015-11-19
        centre-foundation-2015-11-20
        centre-foundation-2015-11-21
        centre-foundation-2015-11-22
        centre-foundation-2015-11-23
        centre-foundation-2015-11-24
        centre-foundation-2015-11-25
        centre-foundation-2015-11-26
        centre-foundation-2015-11-27
        centre-foundation-2015-11-28
        centre-foundation-2015-11-29
        centre-foundation-2015-11-30
        centre-foundation-2015-12-01
        centre-foundation-2015-12-02
        centre-foundation-2015-12-03
        centre-foundation-2015-12-04
        centre-foundation-2015-12-05
        centre-foundation-2015-12-06
        centre-foundation-2015-12-07
        centre-foundation-2015-12-08
        centre-foundation-2015-12-09
        centre-foundation-2015-12-10
        centre-foundation-2015-12-11
        centre-foundation-2015-12-12
        centre-foundation-2015-12-13
        centre-foundation-2015-12-14
        centre-foundation-2015-12-15
        centre-foundation-2015-12-16
        centre-foundation-2015-12-17
        centre-foundation-2015-12-18
        centre-foundation-2015-12-19
        centre-foundation-2015-12-20
        centre-foundation-2015-12-21
        centre-foundation-2015-12-22
        centre-foundation-2015-12-23
        centre-foundation-2015-12-24
        centre-foundation-2015-12-25
        centre-foundation-2015-12-26
        centre-foundation-2015-12-27
        centre-foundation-2015-12-28
        centre-foundation-2015-12-29

        centre-foundation-2015-01-04
        centre-foundation-2015-01-11
        centre-foundation-2015-01-18
        centre-foundation-2015-01-25
        centre-foundation-2015-02-01
        centre-foundation-2015-02-08
        centre-foundation-2014-02-16
        centre-foundation-2015-02-22
        centre-foundation-2015-03-01
        centre-foundation-2015-03-08
        centre-foundation-2014-03-16
        centre-foundation-2015-03-22
        centre-foundation-2015-03-29
        centre-foundation-2015-04-05
        centre-foundation-2014-04-13
        centre-foundation-2015-04-19
        centre-foundation-2015-04-26
        centre-foundation-2015-05-03
        centre-foundation-2015-05-10
        centre-foundation-2015-05-17
        centre-foundation-2015-05-24
        centre-foundation-2015-05-31
        centre-foundation-2015-06-07
        centre-foundation-2015-06-14
        centre-foundation-2015-06-21
        centre-foundation-2015-06-28
        centre-foundation-2015-06-30
        centre-foundation-2014-07-13
        centre-foundation-2014-07-20
        centre-foundation-2014-07-27
        centre-foundation-2014-08-03
        centre-foundation-2014-08-10
        centre-foundation-2014-08-17
        centre-foundation-2014-08-24
        centre-foundation-2014-08-31
        centre-foundation-2014-09-07
        centre-foundation-2014-09-14
        centre-foundation-2014-09-21
        centre-foundation-2014-09-28
        centre-foundation-2014-10-05
        centre-foundation-2014-10-12
        centre-foundation-2014-10-19
        centre-foundation-2014-10-26
        centre-foundation-2014-12-28

        centre-foundation-2013-03-15
        centre-foundation-2013-04-15
        centre-foundation-2013-05-15
        centre-foundation-2013-06-15
        centre-foundation-2013-07-15
        centre-foundation-2013-08-15
        centre-foundation-2013-09-15
        centre-foundation-2013-10-15
        centre-foundation-2013-11-15
        centre-foundation-2013-12-29

        centre-foundation-2014-01-05
        centre-foundation-2014-01-12
        centre-foundation-2014-01-19
        centre-foundation-2014-01-26
        centre-foundation-2014-02-02
        centre-foundation-2014-02-09
        centre-foundation-2014-02-23
        centre-foundation-2014-03-02
        centre-foundation-2014-03-09
        centre-foundation-2014-03-23
        centre-foundation-2014-03-30
        centre-foundation-2014-04-06
        centre-foundation-2014-04-20
        centre-foundation-2014-04-27
        centre-foundation-2014-05-04
        centre-foundation-2014-05-11
        centre-foundation-2014-05-18
        centre-foundation-2014-05-25
        centre-foundation-2014-06-01
        centre-foundation-2014-06-08
        centre-foundation-2014-06-15
        centre-foundation-2014-06-22
        centre-foundation-2014-06-29
        centre-foundation-2014-07-06

        centre-foundation-2013-12-15
      }.map { |name| TarsnapPruner::Archive.new(name) }
    end

    it "keeps the latest backup from each month that's more than a year old" do
      expect(scheduler.monthlies_to_keep.map { |a| a.date.to_s }.sort.reverse).to eq %w{
        2014-12-28
        2014-10-26
        2014-09-28
        2014-08-31
        2014-07-27
        2014-06-29
        2014-05-25
        2014-04-27
        2014-03-30
        2014-02-23
        2014-01-26
        2013-12-29
        2013-11-15
        2013-10-15
        2013-09-15
        2013-08-15
        2013-07-15
        2013-06-15
        2013-05-15
        2013-04-15
        2013-03-15
      }
    end

    it "keeps the latest backup from each week that's more than 90 days old" do
      expect(scheduler.weeklies_to_keep.map { |a| a.date.to_s }.sort.reverse).to eq %w{
        2015-10-02
        2015-09-27
        2015-09-20
        2015-09-13
        2015-09-06
        2015-08-30
        2015-08-23
        2015-08-16
        2015-08-09
        2015-08-02
        2015-07-26
        2015-07-19
        2015-07-12
        2015-07-05
        2015-06-28
        2015-06-21
        2015-06-14
        2015-06-07
        2015-05-31
        2015-05-24
        2015-05-17
        2015-05-10
        2015-05-03
        2015-04-26
        2015-04-19
        2015-04-05
        2015-03-29
        2015-03-22
        2015-03-08
        2015-03-01
        2015-02-22
        2015-02-08
        2015-02-01
        2015-01-25
        2015-01-18
        2015-01-11
        2015-01-04
      }
    end

  end

  context "given archives that have already been pruned" do
    let(:archives) do
      %w{
        2015-10-31
        2015-11-30
        2015-12-01

        2015-12-06
        2015-12-13
        2015-12-20
        2015-12-21

        2015-12-22
        2015-12-23
        2015-12-24
        2015-12-25
        2015-12-26
        2015-12-27
        2015-12-28
        2015-12-29
        2015-12-30
        2015-12-31
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "sees nothing to prune" do
      expect(scheduler.archives_to_prune).to be_empty
    end
  end

  context "given archives with less than ideal backup coverage" do
    let(:archives) do
      %w{
        2015-10-15
        2015-11-20

        2015-12-02
        2015-12-10
        2015-12-21

        2015-12-22
        2015-12-23
        2015-12-24
        2015-12-26
        2015-12-27
        2015-12-29
        2015-12-31
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "doesn't prune any further" do
      expect(scheduler.archives_to_prune).to be_empty
    end
  end

  context "given archives in the future" do
    let(:archives) do
      %w{
        2016-01-01
        2016-01-02
        2016-01-03
      }.map { |n| TarsnapPruner::Archive.new(n) }
    end
    it "doesn't prune anything" do
      expect(scheduler.archives_to_prune).to be_empty
    end
  end

end
