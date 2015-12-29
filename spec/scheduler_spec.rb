require 'spec_helper'

describe TarsnapPruner::Scheduler do
  let(:scheduler) { TarsnapPruner::Scheduler.new(archives) }

  context "when given an empty array of archives" do
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

  context "when given some archives that don't contain a date" do
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

  context "when given some archives that do contain a date in ISO8601 format" do
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

end
