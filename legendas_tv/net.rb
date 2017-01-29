require_relative 'subtitle'
require 'net/http'
require 'nokogiri'
require 'securerandom'

module LegendasTV
  module Net
    class AuthenticationError < StandardError
    end

    def self.GET(url, params = {}, headers = {})
      uri = URI.parse(URI.encode(url))
      uri.query = URI.encode_www_form(params)

      request = ::Net::HTTP::Get.new(uri)

      headers.each { |k, v| request[k] = v }

      ::Net::HTTP.start(uri.hostname) do |http|
        http.request(request)
      end
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
        raise AuthenticationError if response.body =~ /precisa logar-se para efetuar download/

        file = Tempfile.new([::SecureRandom.uuid, Pathname.new(url).extname])
        file.write(response.body)

        block.call(file.path)

        file.close
        file.unlink
      end
    end

    def self.Parse(url)
      body = GET(url, {}, { 'X-Requested-With' => 'XMLHttpRequest' }).body

      results = Nokogiri::HTML(body).xpath('//article/div')

      results.map do |r|
        next if r.attr('class') =~ /banner/
        Subtitle.new(r)
      end.compact
    end
  end
end
