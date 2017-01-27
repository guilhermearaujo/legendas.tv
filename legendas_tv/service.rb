require_relative 'medium'
require_relative 'net'
require 'json'
require 'zip'

module LegendasTV
  class Service
    attr_accessor :working_dir

    BASE_URL = 'http://legendas.tv'.freeze
    BASE_PATH = ENV['HOME'] + '/.legendas.tv'
    TOKEN_PATH = BASE_PATH + '/token.tv'

    LANG = {
      pt: 1,
      en: 2,
      es: 3,
      fr: 4
    }.freeze

    @token = nil

    def initialize
      FileUtils.mkdir_p(BASE_PATH)
      ::Zip.on_exists_proc = true
      @token = open(TOKEN_PATH, 'r').read if File.exist?(TOKEN_PATH)
    end

    def login(username, password)
      raise 'Username or password not provided' unless username && password

      params = {
        'data[User][username]' => username,
        'data[User][password]' => password
      }

      response = Net::POST(BASE_URL + '/login', params)

      raise 'Invalid credentials' unless response['set-cookie'] =~ /au=/

      @token = response['set-cookie'].match(/au=(?<token>[^\s]+);/)[:token]

      open(TOKEN_PATH, 'w') { |f| f.write(@token) }

      true
    end

    def logout
      @token = nil
      open(TOKEN_PATH, 'w') { |f| f.write(nil) }
    end

    def logged_in?
      !@token.nil? && !@token.empty?
    end

    def find_release(release, lang = LANG[:pt])
      path = "/legenda/sugestao/#{release.title}"

      media = JSON.parse(Net::GET(BASE_URL + path).body, symbolize_names: true)
                  .map { |m| Medium.new(m[:_source]) }
                  .select { |m| m.title.casecmp(release.title) == 0 }

      medium =
        if release.movie?
          media.first
        else
          media.find { |m| m.season == release.season }
        end

      raise "Could not find medium for '#{release.release_name}'" unless medium

      find_by(query: release.best_guess_query, id: medium.id, lang: lang, page: 0)
    end

    def download(subtitle)
      raise 'User not logged in' unless @token

      Net::Download(BASE_URL + subtitle.download_url, @token) do |filepath|
        extract(filepath)
      end

      puts "Downloaded subtitle for #{subtitle.release}"
    end

    private

    def find_by(query: '-', id: '-', lang: LANG[:pt], page: 0)
      path = "/legenda/busca/#{query}/#{lang}/-/#{page}/#{id}"

      results = Net::Parse(BASE_URL + path)

      results.concat(find_by(query: query, id: id, lang: lang, page: page + 1)) if results.count >= 24

      results || []
    end

    def extract(filepath)
      if filepath =~ /.rar$/
        `unrar e #{filepath} *.srt #{working_dir}`
      elsif filepath =~ /.zip$/
        unzip(filepath)
      end
    end

    def unzip(filepath)
      ::Zip::File.open(filepath) do |zip|
        zip.each do |entry|
          entry.extract(working_dir + '/' + entry.name) if entry.name =~ /.srt$/
        end
      end
    end
  end
end
