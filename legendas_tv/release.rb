module LegendasTV
  class Release
    attr_reader :basename, :title, :year, :season, :episode, :source, :quality, :codec, :group

    MOVIE_PATTERN =  /(?<title>.+)\.(?<year>\d+)(?<proper>(\.(PROPER|REPACK)))?\.(?<quality>[^\.]+)\.(?<source>.+)\.(?<codec>[^\.]+)[\.-](?<group>[^\.]+)(\[.*\])/
    SERIES_PATTERN = /(?<title>.+)\.S(?<season>\d+)E(?<episode>\d+)(?<proper>(\.(PROPER|REPACK)))?\.(?<quality>[^\.]+)\.(?<source>.+)\.(?<codec>[^\.]+)[\.-](?<group>[^\.]+)(\[.*\])/

    def initialize(filename)
      @basename = File.basename(filename, '.*')

      release_name = basename.gsub(/[\s_]/, '.')

      if info = release_name.match(MOVIE_PATTERN)
        initialize_movie(info)
      elsif info = release_name.match(SERIES_PATTERN)
        initialize_series(info)
      else
        raise "Unknown release '#{basename}'"
      end
    end

    def movie?
      !@year.nil?
    end

    def series?
      !@season.nil?
    end

    def episode_code
      format('S%02dE%02d', season, episode)
    end

    def best_guess_query
      if movie?
        "#{quality}+#{group}"
      else
        "#{episode_code}+#{group}"
      end
    end

    def release_name
      if movie?
        "#{title.tr(' ', '.')}.#{year}.#{quality}.#{source}.#{codec}-#{group}"
      else
        "#{title.tr(' ', '.')}.#{episode_code}.#{quality}.#{source}.#{codec}-#{group}"
      end
    end

    private

    def initialize_movie(info)
      @title   = info[:title].tr('.', ' ')
      @year    = info[:year].to_i
      @quality = info[:quality]
      @source  = info[:source]
      @codec   = info[:codec]
      @group   = info[:group]
      @proper  = !info[:proper].nil?
    end

    def initialize_series(info)
      @title   = info[:title].tr('.', ' ')
      @season  = info[:season].to_i
      @episode = info[:episode].to_i
      @quality = info[:quality]
      @source  = info[:source]
      @codec   = info[:codec]
      @group   = info[:group]
      @proper  = !info[:proper].nil?
    end
  end
end
