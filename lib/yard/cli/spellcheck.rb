require 'yard/spellcheck/checker'
require 'yard/spellcheck/printer'

module YARD
  module CLI
    class Spellcheck < Command

      include YARD::Spellcheck::Printer

      attr_reader :checker

      def initialize
        @checker = YARD::Spellcheck::Checker.new
      end

      def description
        'Spellchecks YARD documentation'
      end

      def run(*args)
        optparse(*args)

        @checker.check! do |element,typos|
          print_typos element, typos
        end
      end

      protected

      def optparse(*args)
        opts = OptionParser.new
        opts.banner = "Usage: yard spellcheck [options]"
        opts.separator ""
        opts.separator description
        opts.separator ""

        opts.on('-D','--dict-dir','Dictionary directory') do |dir|
          FFI::Hunspell.directories << File.expand_path(dir)
        end

        opts.on('-L','--lang LANG','Language to spellcheck for') do |lang|
          @checker.lang = lang
        end

        opts.on('-I','--ignore WORD','Words to ignore') do |word|
          @checker.ignored << word
        end

        opts.on('-a','--add WORD [...]','Adds a word') do |word|
          @added.ignore << word
        end

        common_options(opts)
        parse_options(opts,args)
      end

    end
  end
end
