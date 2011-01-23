require 'ffi/hunspell'

require 'set'

module YARD
  module CLI
    class Spellcheck < Command

      HIGHLIGHT = "\e[31m\e[4m"

      UNHIGHLIGHT = "\e[0m"

      SKIP_TAGS = Set['example', 'since', 'see', 'api']

      attr_reader :lang

      def initialize
        @lang = FFI::Hunspell.lang
        @ignore = Set[]
        @added = Set[]

        @misspelled = Hash.new { |hash,key| hash[key] = 0 }
      end

      def description
        'Spellchecks YARD documentation'
      end

      def run(*args)
        optparse(*args)

        YARD::Registry.load!

        FFI::Hunspell.dict(@lang) do |dict|
          # add user specified words
          @added.each { |word| dict.add(word) }

          YARD::Registry.all.each do |obj|
            docstring = obj.docstring

            unless spellcheck?(docstring,dict)
              line = if docstring.line_range
                       docstring.line_range.first
                     else
                       1
                     end

              puts "Typos in #{docstring.object} (#{docstring.object.file}:#{line})"

              print_highlighted docstring, line
            end

            docstring.tags.each do |tag|
              next if SKIP_TAGS.include?(tag.tag_name)

              if (tag.text && !spellcheck?(tag.text,dict))
                puts "Typos in @#{tag.tag_name} #{tag.name} (#{tag.object.file}:#{tag.object.line})"

                print_highlighted tag.text, tag.object.line
              end
            end
          end
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
          @lang = lang
        end

        opts.on('-I','--ignore WORD [...]','Words to ignore') do |*words|
          @ignore += words
        end

        opts.on('-a','--add WORD [...]','Adds a word') do |*words|
          @added += words
        end

        common_options(opts)
        parse_options(opts,args)
      end

      def highlight(text)
        text.gsub(/\w+/) do |word|
          if @misspelled.include?(word)
            "#{HIGHLIGHT}#{word}#{UNHIGHLIGHT}"
          else
            word
          end
        end
      end

      def print_highlighted(text,line_number=1)
        puts ''

        highlight(text).each_line do |line|
          puts "  #{line_number} #{line}"

          line_number += 1
        end

        puts ''
      end

      def spellcheck?(text,dict)
        valid = true

        text.split(/\s+/).each do |word|
          next if @ignore.include?(word)
          
          if @misspelled.has_key?(word)
            valid = false
          elsif !dict.valid?(word)
            valid = false

            @misspelled[word] += 1
          end
        end

        return valid
      end

    end
  end
end
