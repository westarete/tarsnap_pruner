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

end
