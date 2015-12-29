$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'timecop'
require 'tarsnap_pruner'

TarsnapPruner.configure('.dotenv.rspec')
