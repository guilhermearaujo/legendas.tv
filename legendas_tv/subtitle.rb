require 'time'

module LegendasTV
  class Subtitle
    attr_reader :id, :title, :date, :uploader, :rating, :url, :downloads, :release

    INFO_MATCHER = /^(?<number>\d+) (?<release>.+) (?<downloads>\d+) downloads, nota (?<rating>\d+), enviado por  (?<uploader>.+)  em (?<date>.+) $/
    URL_MATCHER = /^\/download\/(?<id>[\da-fA-F]+)\/(?<title>.+)\/(?<release>.+)$/

    def initialize(element)
      info = element.xpath('.//text()')
                    .map(&:text)
                    .join(' ')
                    .match(INFO_MATCHER)

      @url = element.at_css('a')[:href]
      components = url.match(URL_MATCHER)

      @id        = components[:id]
      @title     = components[:title]
      @date      = Time.parse(info[:date])
      @uploader  = info[:uploader]
      @rating    = info[:rating]
      @downloads = info[:downloads]
      @release   = components[:release].tr('_', '.')
    end

    def download_url
      "/downloadarquivo/#{id}"
    end
  end
end
