require 'yard/spellcheck/checker'
require 'yard/spellcheck/printer'

require 'rake/tasklib'

module YARD
  module Spellcheck
    #
    # @since 0.2.0
    #
    class Task < ::Rake::TaskLib

      include YARD::Spellcheck::Printer

      # The spellchecker
      #
      # @return [Checker]
      attr_reader :checker

      # Classes/Modules to spellcheck
      #
      # @return [Array<String>]
      attr_accessor :constants

      #
      # Initializes and defines the `yard:spellcheck` task.
      #
      # @param [Hash] options
      #   Additional options for {Checker#initialize}.
      #
      # @option options [Array<String>] :constants ([])
      #   The Classes/Modules to spellcheck.
      #
      # @yield [task]
      #   If a block is given, it will be passed the newly created task object
      #   for further configuration.
      #
      # @yieldparam [Task] task
      #   The newly created Task.
      #
      # @see Checker#initialize
      #
      def initialize(options={})
        @constants = options.fetch(:constants,[])
        @checker   = Checker.new(options)

        yield self if block_given?
        define
      end

      #
      # Defines the `yard:spellcheck` task.
      #
      def define
        namespace :yard do
          desc 'Spellchecks the generated YARD documentation'
          task :spellcheck do
            @checker.check!(@constants) do |element,typos|
              print_typos element, typos
            end

            puts "Statistics"
            print_stats @checker
          end
        end
      end

    end
  end
end
