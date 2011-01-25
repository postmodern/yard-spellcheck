require 'yard/spellcheck/checker'

module YARD
  module Spellcheck
    #
    # Provides methods for printing the typos found in YARD Documentation.
    #
    module Printer
      # Highlights text
      HIGHLIGHT = "\e[31m\e[4m"

      # Unhighlights text
      UNHIGHLIGHT = "\e[0m"

      #
      # Prints typos in a YARD Documentation element.
      #
      # @param [YARD::Docstring, YARD::Tags::Tag] element
      #   The element that the typos occurred in.
      #
      # @param [Set<String>] typos
      #   The typos that were found in the element.
      #
      def print_typos(element,typos)
        case element
        when YARD::Docstring
          line = if element.line_range
                   element.line_range.first
                 else
                   1
                 end

          puts "Typos in #{element.object} (#{element.object.file}:#{line})"

          print_text line, element, typos
        when YARD::Tags::Tag
          puts "Typos in @#{element.tag_name} #{element.name} (#{element.object.file}:#{element.object.line})"

          print_text element.object.line, element.text, typos
        end
      end

      #
      # Prints text containing typos.
      #
      # @param [Integer] line_number
      #   The line number that the text starts on.
      #
      # @param [String] text
      #   The text to print.
      #
      # @param [Set<String>] typos
      #   The typos that occurred within the text.
      #
      def print_text(line_number,text,typos)
        # highlight the typos
        highlighted = text.gsub(Checker::WORD_REGEXP) do |word|
          if typos.include?(word)
            "#{HIGHLIGHT}#{word}#{UNHIGHLIGHT}"
          else
            word
          end
        end

        puts ''

        # print the lines
        highlighted.each_line do |line|
          puts "  #{line_number} #{line}"
          line_number += 1
        end

        puts ''
      end

      #
      # Prints statistics gathered by the spellchecker.
      #
      # @param [Checker] checker
      #   The spellchecker.
      #
      def print_stats(checker)
        stats = checker.misspelled.sort_by { |word,count| -count }

        stats.each_with_index do |(word,count),index|
          puts "  #{index + 1}. #{word} (#{count})"
        end
      end
    end
  end
end
