require 'ffi/hunspell'
require 'set'

module YARD
  module Spellcheck
    #
    # Handles loading and spellchecking YARD Documentation.
    #
    class Checker

      # YARD tags to not spellcheck.
      SKIP_TAGS = Set['example', 'since', 'see', 'api']

      # The Regexp to use for scanning in words.
      WORD_REGEXP = /[^\W_][\w'-]*[^\W_]/

      # The Regexp to filter out Acronyms.
      ACRONYM_REGEXP = /(([A-Z]\.){2,}|[A-Z]{2,})/

      # The Regexp to filter out CamelCase words.
      CAMEL_CASE_REGEXP = /([A-Z][a-z]+){2,}/

      # The language to spellcheck against.
      attr_accessor :lang

      # The words to ignore.
      attr_reader :ignore

      # The words to add to the dictionary.
      attr_reader :added

      # The misspelled words.
      attr_reader :misspelled

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

        if options[:ignore]
          @ignored += options[:add]
        end

        if options[:add]
          @added += options[:add]
        end

        @misspelled = Hash.new { |hash,key| hash[key] = 0 }
      end

      #
      # Spellchecks the YARD Documentation.
      #
      # @param [Array<String>] names
      #   The Classes/Modules to spellcheck.
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
      def check!(names=[],&block)
        return enum_for(:check!) unless block

        # load the YARD cache
        YARD::Registry.load!

        # clear any statistics from last run
        @misspelled.clear

        FFI::Hunspell.dict(@lang) do |dict|
          # add user specified words
          @added.each { |word| dict.add(word) }

          unless names.empty?
            names.each do |name|
              if (obj = YARD::Registry.at(name))
                spellcheck_object(obj,dict,&block)
              end
            end
          else
            YARD::Registry.each do |obj| 
              spellcheck_object(obj,dict,&block)
            end
          end
        end
      end

      protected

      #
      # Spellchecks a YARD Documentation object.
      #
      # @param [YARD::CodeObject::Base] obj
      #   The YARD Documentation object.
      #
      # @param [FFI::Hunspell::Dictionary] dict
      #   The dictionary to spellcheck against.
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
      def spellcheck_object(obj,dict)
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
      #   The misspelled words from the text.
      #
      def spellcheck(text,dict)
        typos = Set[]

        text.scan(WORD_REGEXP).each do |word|
          # ignore all underscored names
          next if word.include?('_')

          # ignore all acronyms and CamelCase words
          next if (word =~ ACRONYM_REGEXP || word =~ CAMEL_CASE_REGEXP)

          if (@misspelled.has_key?(word) || !dict.valid?(word))
            @misspelled[word] += 1

            typos << word
          end
        end

        return typos
      end

    end
  end
end
