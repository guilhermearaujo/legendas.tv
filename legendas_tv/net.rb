require_relative 'subtitle'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'securerandom'

module LegendasTV
  module Net
    def self.GET(url, params = {})
      uri = URI.parse(URI.encode(url))
      uri.query = URI.encode_www_form(params)

      ::Net::HTTP.get_response(uri)
    end

    def self.POST(url, params = {})
      uri = URI.parse(url)

      ::Net::HTTP.post_form(uri, params)
    end

    def self.Download(url, token, &block)
      uri = URI.parse(url)

      request = ::Net::HTTP::Get.new(uri.path)
      request.add_field('Cookie', "au=#{token};")

      response = ::Net::HTTP.new(uri.host, uri.port).start do |http|
        http.request(request)
      end

      if response.is_a?(::Net::HTTPRedirection)
        # Follow redirect
        Download(response['location'], token, &block)
      else
        file = Tempfile.new([::SecureRandom.uuid, Pathname.new(url).extname])
        file.write(response.body)

        block.call(file.path)

        file.close
        file.unlink
      end
    end

    def self.Parse(url)
      uri = URI.encode(url)
      results = Nokogiri::HTML(open(uri)).xpath('//article/div')

      results.map do |r|
        next if r.attr('class') =~ /banner/
        Subtitle.new(r)
      end.compact
    end
  end
end
