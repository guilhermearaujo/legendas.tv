require 'pathname'
require 'time'

module LegendasTV
  module Unrar
    class File
      LIST_MATCHER = /(?<size>\d+)\s+(?<date>[\d-]+ [\d:]+)\s+(?<name>.+)$/

      def self.open(archive)
        raise 'File does not exist' unless ::File.exist?(archive)

        contents = `unrar l #{archive}`

        raise 'File is not a RAR archive' if contents =~ /is not RAR archive/

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

        raise 'File is not a RAR archive' if contents =~ /is not RAR archive/

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

        @basename = ::Pathname.new(name).basename
      end

      def extract(destination, overwrite = true)
        pathname = ::Pathname.new(destination)
        dir = pathname.dirname
        file = pathname.basename

        opts = overwrite ? '-y' : ''

        `unrar e #{opts} #{@archive} #{name} #{dir} && mv #{dir}/#{@basename} #{dir}/#{file}`
      end
    end
  end
end
