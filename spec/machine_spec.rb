require 'spec_helper'

describe TarsnapPruner::Machine do
  let(:key_file) { File.join('spec', 'fixtures', 'keys', 'tarsnap-hostname1.example.com.key') }
  let(:tarsnap) {
    double('tarsnap',
           list_archives: "hostname1-2015-05-17\nhostname1-2015-05-15\nhostname1-2015-05-16",
           fsck: nil,
           delete: nil )
  }
  let(:machine) { TarsnapPruner::Machine.new(key_file, tarsnap) }

  describe '.key_files' do
    let(:key_files) { TarsnapPruner::Machine.key_files }
    it "returns an array of tarsnap key files" do
      expect(key_files).to be_a_kind_of Enumerable
      expect(key_files.length).to be > 0
      expect(key_files.first).to match %r{/tarsnap-[\w.]+\.key$}
    end
  end

  describe '.all' do
    let(:result) { TarsnapPruner::Machine.all }
    it "returns an array of Machines, one for each key file" do
      expect(result).to be_a_kind_of Enumerable
      expect(result.length).to eq TarsnapPruner::Machine.key_files.length
      expect(result.first).to be_a_kind_of TarsnapPruner::Machine
      expect(result.first.key_file).to eq TarsnapPruner::Machine.key_files.first
    end
  end

  describe '#hostname' do
    context "when the key filename follows the specified format" do
      it "extracts the hostname from the keyfile name" do
        expect(machine.hostname).to eq 'hostname1.example.com'
      end
    end
    context "when the key filename does not follow the specified format" do
      let(:key_file) { "whatever.key" }
      it 'returns "unknown"' do
        expect(machine.hostname).to eq 'unknown'
      end
    end
  end

  describe '#archives' do
    let(:archive) { machine.archives.first }
    it "returns a sorted array of Archive objects from tarsnap" do
      expect(archive).to be_an_instance_of TarsnapPruner::Archive
      expect(archive.name).to eq 'hostname1-2015-05-15'
    end
  end

  describe '#delete' do
    let(:cache_glob) { File.join(ENV['CACHES_DIRECTORY'], 'cache-*') }
    before do
      FileUtils.rm_rf(cache_glob)
    end
    context "if there are no archives to delete" do
      it "does nothing" do
        expect { machine.delete([]) }.to_not raise_error
      end
    end
    context "when given archives to delete" do
      let(:archives) {
        %w{
          hostname-2015-01-15
          hostname-2015-02-15
          hostname-2015-03-15
        }.map { |n| TarsnapPruner::Archive.new(n) }
      }
      def do_delete
        machine.delete(archives)
      end
      it "calls tarsnap --fsck to initialize a temporary cache" do
        expect(tarsnap).to receive(:fsck)
        do_delete
      end
      it "calls tarsnap -d for each archive" do
        archives.each do |a|
          expect(tarsnap).to receive(:delete).with(a, anything).once
        end
        do_delete
      end
      it "uses the temporary cache" do
        expect(tarsnap).to receive(:delete).with(anything, /cache/)
        do_delete
      end
      it "deletes the cache directory after it's done" do
        expect(Dir.glob(cache_glob)).to be_empty
      end
    end
  end

end
