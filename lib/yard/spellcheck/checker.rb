require 'ffi/hunspell'
require 'set'

module YARD
  module Spellcheck
    class Spellchecker

      # YARD tags to not spellcheck
      SKIP_TAGS = Set['example', 'since', 'see', 'api']

      # The language to spellcheck against.
      attr_accessor :lang

      # The words to ignore
      attr_reader :ignore

      # The words to add to the dictionary
      attr_reader :added

      #
      # Initializes the spellchecker.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [String, Symbol] :lang (FFI::Hunspell.lang)
      #   The language to spellcheck against.
      #
      # @option options [Array, Set] :ignore
      #   The words to ignore.
      #
      # @option options [Array, Set] :add
      #   The words to add to the dictionary.
      #
      def initialize(options={})
        @lang = options.fetch(:lang,FFI::Hunspell.lang)
        @ignore = Set[]
        @added = Set[]
        @misspelled = Hash.new { |hash,key| hash[key] = 0 }

        if options[:ignore]
          @ignored += options[:add]
        end

        if options[:add]
          @added += options[:add]
        end
      end

      #
      # Spellchecks the YARD Documentation.
      #
      # @yield [element, typos]
      #   The given block will be passed each element and any typos found.
      #
      # @yieldparam [YARD::Docstring, YARD::Tag] element
      #   An element from the YARD Documentation.
      #
      # @yieldparam [Set<String>] typos
      #   Any typos found within the element.
      #
      # @return [Enumerator]
      #   If no block is given, an Enumerator will be returned.
      #
      def check!
        return enum_for(:check!) unless block_given?

        # load the YARD cache
        YARD::Register.load!

        # clear any statistics from last run
        @misspelled.clear

        FFI::Hunspell.dict(@lang) do |dict|
          # add user specified words
          @added.each { |word| dict.add(word) }

          YARD::Registry.all.each do |obj|
            docstring = obj.docstring

            unless (typos = spellcheck(docstring,dict)).empty?
              yield docstring, typos
            end

            docstring.tags.each do |tag|
              next if SKIP_TAGS.include?(tag.tag_name)

              if tag.text
                unless (typos = spellcheck(tag.text,dict)).empty?
                  yield tag, typos
                end
              end
            end
          end
        end

        protected

        #
        # Spellchecks a piece of text.
        #
        # @param [String] text
        #   The text to spellcheck.
        #
        # @param [FFI::Hunspell::Dictionary] dict
        #   The dictionary to use.
        #
        # @return [Set<String>]
        #   The mispelled words from the text.
        #
        def spellcheck(text,dict)
          typos = Set[]

          text.scan(/[\w-]+/).each do |word|
            if (@ignore.include?(word) || typos.include?(word))
              next
            end

            if (@misspelled.has_key?(word) && !dict.valid?(word))
              @misspelled[word] += 1

              typos << word
            end
          end

          return typos
        end
      end
    end
  end
end
