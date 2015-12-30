require 'spec_helper'

describe TarsnapPruner::Archive do
  let(:archive) { TarsnapPruner::Archive.new(name) }
  let(:name) { "The Name" }

  describe '#name' do
    it "returns the name that was passed to the initializer" do
      expect(archive.name).to eq name
    end
  end

  describe '#date' do
    context "when the name contains an iso8601 date" do
      let(:name) { "hostname-2015-05-15" }
      it "returns a Date object for that date" do
        expect(archive.date).to eq Date.new(2015,5,15)
      end
    end
    context "when there is more than one date in the name" do
      let(:name) { "hostname-2014-03-02-2015-06-15" }
      it "returns a Date object for the last one" do
        expect(archive.date).to eq Date.new(2015,6,15)
      end
    end
    context "when there is no date in the name" do
      let(:name) { "hostname" }
      it "returns nil" do
        expect(archive.date).to be nil
      end
    end
  end

  describe '#to_s' do
    it "returns the name" do
      expect(archive.to_s).to eq 'The Name'
    end
  end

  describe '#elapsed' do
    context "when there is a date" do
      let(:name) { "hostname-2015-05-15" }
      it "returns the number of days that have elapsed since that date" do
        expect(archive.elapsed).to eq(Date.today - Date.new(2015,5,15))
      end
    end
    context "when there is no date" do
      let(:name) { "hostname" }
      it "returns nil" do
        expect(archive.elapsed).to be nil
      end
    end
  end

end