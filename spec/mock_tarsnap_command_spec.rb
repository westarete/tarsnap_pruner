require 'spec_helper'
require 'shared_examples_for_tarsnap_command'
require 'tarsnap_pruner/mock_tarsnap_command'

describe TarsnapPruner::MockTarsnapCommand do
  subject(:command) { TarsnapPruner::MockTarsnapCommand.new("path/to/file.key") }

  it_behaves_like "TarsnapCommand"

  describe '#list_archives' do
    it "returns a multi-line string of archive names, one per line" do
      expect(command.list_archives.split).to eq %w{ hostname-2015-05-12 hostname-2015-05-13 hostname-2015-05-14 }
    end
  end

end
