require 'spec_helper'
require 'shared_examples_for_tarsnap_command'

describe TarsnapPruner::TarsnapCommand do
  subject { TarsnapPruner::TarsnapCommand.new("path/to/file.key") }

  it_behaves_like "TarsnapCommand"

end
