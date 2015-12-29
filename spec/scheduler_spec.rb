require 'spec_helper'

describe TarsnapPruner::Scheduler do

  # We freeze all of the Scheduler tests to a static date, so that we can
  # use concrete examples for our data, as opposed to having to do relative
  # calculations to the current time.
  let(:today) { Date.new(2015,12,20) }
  around do |example|
    Timecop.freeze(today)
    example.run
    Timecop.return
  end

  # Keep daily backups back to 14 days, weeklies back to 60 days, and
  # monthlies after that.
  let(:daily_boundary) { 14 }
  let(:weekly_boundary) { 60 }
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
        hostname-2015-12-20
        hostname-2015-12-19
        hostname-2015-12-18
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
      90.times.collect do |i|
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
      expect(scheduler.dailies).to eq archives.first(daily_boundary)
    end
    it "sets the weeklies" do
      expect(scheduler.weeklies).to eq archives[daily_boundary...weekly_boundary]
    end
    it "sets the monthlies" do
      expect(scheduler.monthlies).to eq archives[weekly_boundary..archives.length]
    end
  end

end
