# Legendas.tv Automatic Downloader

A script that automagically download subtitles for your movies and series from [Legendas.tv].  
If you enjoy their work, don't forget to [support them].

## How to install

* Clone this project: `$ git clone https://github.com/guilhermearaujo/legendas.tv.git`
* Install [Unrar]: see [how to install](#installing-unrar)
* Install [Colorize]: `$ gem install colorize`
* Install [Nokogiri]: `$ gem install nokogiri`
* Install [Rubyzip]: `$ gem install rubyzip`

## Usage

Simply call the script and provide a path to a video file or a directory containing video files:

```bash
$ ./legendastv "/path/to/media/That.Awesome.Movie.2017.2160p.x264-FLIX.mkv"
$ ./legendastv "/path/to/media/Series/The Series Season 1"
```

**NOTE**: This script will work as long as you keep the original filename of the releases, according
to the Scene standards:

| Release | Filename                             |
|---------|--------------------------------------|
| Movie   | `Title.Year.Quality.Codec-Group.ext` |
| Series  | `Title.S#E#.Quality.Codec-Group.ext` |

### Logging in

The first time you run the script, it will ask for your Legendas.tv credentials. Type them in, and
they will be stored safely in your computer, so you don't need to re-enter them at every use.

### Logging out or switching accounts

May you wish to remove your user information, run `$ ./legendastv --logout` to wipe your user data.

### Scheduled downloads

If you have a media folder to keep your movies and series, you can add a Cron job:

```bash
0 * * * * /path/to/legendas.tv /path/to/media/ # Run every hour
```

## Installing Unrar

### On macOS

Using Homebrew: `$ brew install unrar`

### On Linux

* Using apt-get: `$ apt-get install unrar`
* Download the binary from [Unrar]
* From source: download from [Unrar] and run `$ make && make install`

**NOTE**: this project is **not** compatible with `unrar-free`.

[Legendas.tv]: http://legendas.tv
[support them]: http://legendas.tv/vip
[Unrar]: http://www.rarlab.com/rar_add.htm
[Colorize]: https://github.com/fazibear/colorize
[Nokogiri]: https://github.com/sparklemotion/nokogiri
[Rubyzip]: https://github.com/rubyzip/rubyzip
