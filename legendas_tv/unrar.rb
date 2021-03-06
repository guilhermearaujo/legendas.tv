require 'pathname'
require 'time'

unless system('unrar -V > /dev/null 2>&1')
  puts 'Unrar is not installed. Check http://www.rarlab.com/rar_add.htm'
  raise 'unrar not found'
end

module LegendasTV
  module Unrar
    class File
      LIST_MATCHER = /(?<size>\d+)\s+(?<date>[\d-]+ [\d:]+)\s+(?<name>.+)$/

      def self.open(archive)
        raise 'File does not exist' unless ::File.exist?(archive)

        contents = `unrar l #{archive}`

        raise 'File is not a RAR archive' if contents =~ /is not RAR archive/i

        files = []

        contents.each_line do |line|
          next unless m = line.match(LIST_MATCHER)
          files << Rar.new(archive, m[:name], m[:size], m[:date])
        end

        yield files

        return
      end

      def self.list(archive)
        raise 'File does not exist' unless ::File.exist?(archive)

        contents = `unrar l #{archive}`

        raise 'File is not a RAR archive' if contents =~ /is not RAR archive/i

        puts 'Date                       Size        Name'
        puts '-------------------------  ----------  ------------------------------------------'

        contents.each_line do |line|
          next unless m = line.match(LIST_MATCHER)
          file = Rar.new(archive, m[:name], m[:size], m[:date])
          puts "%s  %10d  %s" % [file.date, file.size, file.name]
        end

        return
      end
    end

    class Rar
      attr_reader :name, :size, :date
      def initialize(archive, name, size, date)
        @archive = archive
        @name = name
        @size = size
        @date = Time.parse(date)

        @basename = ::Pathname.new(name).basename.to_s
      end

      def extract(destination, overwrite = true)
        pathname = ::Pathname.new(destination)
        dir = pathname.dirname.to_s
        file = pathname.basename.to_s

        opts = overwrite ? '-y' : ''

        `unrar e #{opts} "#{@archive}" "#{name}" "#{dir}" && mv "#{dir}/#{@basename}" "#{dir}/#{file}"`
      end
    end
  end
end
