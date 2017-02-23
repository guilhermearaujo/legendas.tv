require_relative 'medium'
require_relative 'net'
require_relative 'unrar'
require 'colorize'
require 'json'
require 'zip'

module LegendasTV
  class Service
    attr_accessor :working_dir

    BASE_URL = 'http://legendas.tv'.freeze
    PAGE_LENGTH = 24
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

      raise 'Invalid credentials' unless response['set-cookie'] =~ /au=/i

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

    def find_and_download(release, lang = LANG[:pt])
      medium = find_medium(release)

      raise "Could not find medium for '#{release.release_name}'" unless medium

      subtitles = find_subtitles(release.best_guess_query, medium.id, lang)

      raise "No subtitle found for '#{release.release_name}'" if subtitles.empty?

      download(release, subtitles.first)
    rescue Net::AuthenticationError
      logout
      raise 'Your credentials have expired. Please, log in again to be able to download'
    rescue Net::NotFound
      raise 'The subtitle was not found on the server'
    end

    private

    def find_medium(release)
      path = "/legenda/sugestao/#{release.title}"

      media = JSON.parse(Net::GET(BASE_URL + path).body, symbolize_names: true)
                  .map { |m| Medium.new(m[:_source]) }
                  .select { |m| m.title.gsub('.', '').casecmp(release.title) == 0 }

      if release.movie?
        media.first
      else
        media.sort_by(&:id).find { |m| m.season == release.season }
      end
    end

    def find_subtitles(query = '-', id = '-', lang = LANG[:pt], page = 0)
      path = "/legenda/busca/#{query}/#{lang}/-/#{page}/#{id}"

      results = Net::Parse(BASE_URL + path)

      return results if results.count < PAGE_LENGTH

      results.concat(find_subtitles(query, id, lang, page + 1))
    end

    def download(release, subtitle)
      raise 'User not logged in' unless @token

      Net::Download(BASE_URL + subtitle.download_url, @token) do |archive|
        extract(release, archive)
      end

      puts "Downloaded subtitle for #{subtitle.release}".green
    end

    def extract(release, archive)
      if archive =~ /.rar$/i
        unrar(release, archive)
      elsif archive =~ /.zip$/i
        unzip(release, archive)
      end
    end

    def unrar(release, archive)
      Unrar::File.open(archive) do |rar|
        find_and_extract(rar, release, "#{working_dir}/#{release.basename}.srt")
      end
    end

    def unzip(release, archive)
      ::Zip::File.open(archive) do |zip|
        find_and_extract(zip, release, "#{working_dir}/#{release.basename}.srt")
      end
    end

    def find_and_extract(files, release, filename)
      subs = files.select { |s| s.name =~ /\.srt/i }

      if subs.count == 1
        subs.first.extract(filename)
      else
        sub = subs.find do |s|
          if release.series?
            s.name =~ /E[0]*#{release.episode}\..*#{release.group}\.srt$/i
          else
            s.name =~ /#{release.group}\.srt$/i
          end
        end

        sub.extract(filename)
      end
    end
  end
end
