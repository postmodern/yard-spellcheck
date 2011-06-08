require 'yard/spellcheck/checker'
require 'yard/spellcheck/printer'

module YARD
  module CLI
    #
    # The `yard-spellcheck` command.
    #
    class Spellcheck < Command

      # The spellchecker.
      attr_reader :checker

      #
      # Initializes the spellcheck command.
      #
      def initialize
        @checker = YARD::Spellcheck::Checker.new
        @names = []
        @stats = false
      end

      #
      # The command description.
      #
      # @return [String]
      #   Description.
      #
      def description
        'Spellchecks YARD documentation'
      end

      #
      # Runs the spellcheck command.
      #
      # @param [Array<String>] args
      #   The arguments for the command.
      #
      def run(*args)
        optparse(*args)

        CLI::Yardoc.run('-c', '-n', '--no-stats')

        @checker.check!(@names) do |element,typos|
          print_typos element, typos
        end

        if @stats
          puts "Statistics"
          print_stats @checker
        end

        exit -1 unless @checker.misspelled.empty?
      end

      protected

      include YARD::Spellcheck::Printer

      #
      # Parses the command options.
      #
      # @param [Array<String>] args
      #   The arguments for the command.
      #
      def optparse(*args)
        opts = OptionParser.new
        opts.banner = "Usage: yard spellcheck [options]"
        opts.separator ""
        opts.separator description
        opts.separator ""

        opts.on('-D','--dict-dir DIR','Dictionary directory') do |dir|
          FFI::Hunspell.directories << File.expand_path(dir)
        end

        opts.on('-c','--check [CLASS | MODULE]','Classes/Modules to spellcheck') do |name|
          @names << name
        end

        opts.on('-L','--lang LANG','Language to spellcheck for') do |lang|
          @checker.lang = lang
        end

        opts.on('-I','--ignore WORD','Words to ignore') do |word|
          @checker.ignored << word
        end

        opts.on('-a','--add WORD [...]','Adds a word') do |word|
          @checker.added << word
        end

        opts.on('-S','--statistics','Print statistics') do
          @stats = true
        end

        common_options(opts)
        parse_options(opts,args)
      end

    end
  end
end
