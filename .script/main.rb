#!/usr/bin/env ruby

require "pp"
require "uri"
require "erb"
require "json"
require "time"
require "optparse"
require "pathname"
require "kramdown"
require "kramdown-parser-gfm"
require "md2indesign"


require "./.script/builder/builder.rb"
require "./.script/helper/erb_helper.rb"
include ERBHelper

# debugger
def j(o)
  puts caller.first, JSON.pretty_generate(o)
end


if __FILE__ == $PROGRAM_NAME
  opt = OptionParser.new

  dir  = "./blog.jxck.io/entries/**/*.md"
  icon = "https://jxck.io/assets/img/jxck" # 拡張子は template で補完
  blog = Builder::BlogBuilder.new(dir, icon)


  dir  = "./mozaic.fm/episodes/**/*.md"
  icon = "https://mozaic.fm/assets/img/mozaic" # 拡張子は template で補完
  podcast = Builder::PodcastBuilder.new(dir, icon)



  # Markdown to HTML
  opt.on("-b path/to/entry", "--blog ./path/to/entry.md") {|path|
    blog.build(path)
  }
  opt.on("-p path/to/episode", "--podcast ./path/to/episode.md") {|path|
    podcast.build(path)
  }
  opt.on("--full") {
    blog.build_all
    podcast.build_all
  }


  # Update Index/Tags
  opt.on("--blogindex") {|v|
    blog.index
    blog.tags
  }
  opt.on("--podcastindex") {|v|
    podcast.index
  }


  ## Update Feed
  opt.on("--blogfeed") {|v|
    blog.feed
  }
  opt.on("--podcastfeed") {|v|
    podcast.feed
  }


  ## Test
  opt.on("--blogtest") {|v|
    puts "test builing blog"
    path = "./blog.jxck.io/entries/2016-01-27/new-blog-start.md"
    blog.build(path)
    blog.build_all
    blog.feed
  }
  opt.on("--podcasttest") {|v|
    puts "test building podcast"
    # path = "./mozaic.fm/episodes/0/introduction-of-mozaicfm.md"
    path = "./mozaic.fm/episodes/1/webcomponents.md"
    podcast.build(path)
    podcast.build_all
    podcast.feed
    podcast.index
  }
  opt.on("--marktest") {|v|
    puts "test markup"
    path = "./.script/test/test.md"
    idtag = Builder::IdtagBuilder.new()
    idtag.build(path)
  }

  opt.on("--test") {|v|
    path = "./blog.jxck.io/entries/2016-01-27/new-blog-start.md"
    blog.build(path)
    blog.feed
    blog.index

    path = "./mozaic.fm/episodes/1/webcomponents.md"
    podcast.build(path)
    # podcast.feed
    podcast.index

    path = "./.script/test/test.md"
    idtag = Builder::IdtagBuilder.new()
    idtag.build(path)
  }

  opt.on("-t") {|v|
    path = "./.script/test/test.md"
    dir  = File.dirname(path)

    class Entry
      attr_reader :article, :title
      def initialize(article, title="")
        @article = article
        @title   = title
      end
    end


    id_format   = MD2Indesign::Format::Idtag.new(highlight: "mono")
    id_builder  = Builder::Builder.new(id_format)
    id_body     = id_builder.build(path)
    id_entry    = Entry.new(id_body)
    id_template = ERB.new(File.read("./.script/template/page.idtag.erb"))
    id_tag      = id_template.result(id_entry.instance_eval{binding}).strip
    File.write("#{dir}/test.idtag", id_tag)

    html_format   = MD2Indesign::Format::HTML.new(highlight: "mono")
    html_builder  = Builder::Builder.new(html_format)
    html_body     = html_builder.build(path)
    html_entry    = Entry.new(html_body, "This is Title")
    html_template = ERB.new(File.read("./.script/template/page.html.erb"))
    html          = html_template.result(html_entry.instance_eval{binding}).strip
    File.write("#{dir}/test.html", html)
  }

  opt.on("-h") {|v|
    puts "make から叩いて"
  }

  puts "make から叩いて" if ARGV.empty?
  opt.parse!(ARGV)
end