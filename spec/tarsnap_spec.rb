require 'spec_helper'

describe TarsnapPruner::Tarsnap do
  subject { TarsnapPruner::Tarsnap.new("path/to/file.key") }

  it { is_expected.to respond_to :list_archives }
  it { is_expected.to respond_to :fsck }
  it { is_expected.to respond_to :delete }

end
