require "tarsnap_pruner/version"
require "tarsnap_pruner/archive"
require "tarsnap_pruner/scheduler"
require "tarsnap_pruner/tarsnap"
require "tarsnap_pruner/machine"

require 'dotenv'

module TarsnapPruner

  module_function

  def configure(config_file=nil)
    if config_file
      Dotenv.load(config_file)
    else
      Dotenv.load
    end
  end

end
