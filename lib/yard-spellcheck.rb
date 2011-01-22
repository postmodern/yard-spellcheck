require 'yard'
require 'yard/cli/spellcheck'

YARD::CLI::CommandParser.commands[:spellcheck] = YARD::CLI::Spellcheck
