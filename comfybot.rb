require 'cinch'
require 'cinch/plugins/identify'
require 'open-uri'

$dearleader = "your_nick" # Place your nick here.
$accesslvls = ["comrades.txt", "ignored.txt"]

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.network-goes-here.tld" # Network
    c.channels = ["#channel-here"] # Channel
    c.nick = "bot-name" # Change bot name
    c.plugins.plugins = [Cinch::Plugins::Identify]
    c.plugins.options[Cinch::Plugins::Identify] = {
      :password => "loldongs", # Put your password here if you use nicksev.
      :type => :nickserv,
    }
  end

  helpers do # You're gonna want to have grep on your system.
    def is_comrade?(user)
      system("grep #{user.nick} #{$accesslvls[0]}") # Checks to see if nick is a comrade.
    end
    
    def is_ignored?(user)
      system("grep #{user.nick} #{$accesslvls[1]}") # Checks to see if a nick is ignored.
    end

    def shorten(url)
      url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
      url == "Error" ? nil : url
    rescue OpenURI::HTTPError
      nil
    end
  end

  # Basic bot utility.

  on :message, ".bots" do |m|
    unless is_ignored?(m.user)
      m.reply "Reporting in! [" + Format(:red, "Ruby") + "] Do " + Format(:bold, :purple, ":info") + " for cool stuff."
    end
  end

  on :message, ":info" do |m|
    unless is_ignored?(m.user)
      m.reply "I'm comfy's bot. " + Format(:teal, "https://github.com/comfyasfuck/comfybot-ruby") # Change this
      m.reply "If u wun b cumrag, ask comfy. Do " + Format(:bold, :blue, ":comrades view") + " to see the list."
    end
  end

  # Join and part from channels, send messages to chans and users.
  
  on :message, /:join (.+)/ do |m, channel|
    if m.user.nick == $dearleader || is_comrade?(m.user) == true
      bot.join(channel)
      unless m.user.nick == $dearleader
        User("#{$dearleader}").send Format("I've joined %s per the request of %s." % [Format(:green, "#{channel}"), Format(:blue, "#{m.user.nick}")])
      end
    else
      m.reply Format("%s %s isn't a comrade." % [Format(:bold, :red, "DENIED:"), Format(:green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to see stuff." % [Format(:bold, :blue, ":comrades view"), Format(:bold, :red, ":ignored view")])
    end
  end

  on :message, /:part (.+)/ do |m, channel|
    channel = channel || m.channel
    if m.user.nick == $dearleader || is_comrade?(m.user) == true
      if channel
        bot.part(channel)
      end
      unless m.user.nick == $dearleader
        User("#{$dearleader}").send Format("I've parted from %s per the request of %s." % [Format(:green, "#{channel}"), Format(:blue, "#{m.user.nick}")])
      end
    else
      m.reply Format("%s %s isn't a comrade." % [Format(:bold, :red, "DENIED:"), Format(:green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to see stuff." % [Format(:bold, :blue, ":comrades view"), Format(:bold, :red, ":ignored view")])
    end
  end

  on :message, /:send (.+?) (.+)/ do |m, who, text|
    if m.user.nick == $dearleader || is_comrade?(m.user) == true
      unless who == bot.nick
        Channel(who).send text
      end
    else
      m.reply Format("%s %s isn't a comrade." % [Format(:bold, :red, "DENIED:"), Format(:green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to see stuff." % [Format(:bold, :blue, ":comrades view"), Format(:bold, :red, ":ignored view")])
    end
  end

  on :message, /:shorten (.+)/ do |m, text|
    unless is_ignored?(m.user)
      if text.include? "http" and text.include? "." and text.include? "//" and text.include? ":"
        m.reply shorten(text)
      else
        m.reply Format(:bold, :red, "ERROR:") + " Invalid URL."
      end
    end
  end

  on :message, /:comrades (.+?) (.+)/ do |m, who, text|
    if m.user.nick == $dearleader || is_comrade?(m.user) == true
      if text == "add"
        open('comrades.txt', 'a') do |f|
          f.puts "#{who}"
        end
        m.reply Format("Added %s to %s." % [Format(:green, "#{who}"), Format(:bold, :blue, "comrades")])
      elsif text == "del"
        system("sed -i '/#{who}/d' comrades.txt")
        m.reply Format("Removed %s from %s." % [Format(:green, "#{who}"), Format(:bold, :blue, "comrades")])
      else
        m.reply Format(:bold, :red, "ERROR:") + " Invalid command."
      end
    else
      m.reply Format("%s %s isn't a comrade." % [Format(:bold, :red, "DENIED:"), Format(:green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to see stuff." % [Format(:bold, :blue, ":comrades view"), Format(:bold, :red, ":ignored view")])
    end
  end

  on :message, ":comrades view" do |m|
    comView = File.open("#{$accesslvls[0]}").map(&:chomp).join(", ")
    m.reply "My comrades are " + Format(:bold, :blue, comView)
  end

  on :message, /:ignored (.+?) (.+)/ do |m, who, text|
    if m.user.nick == $dearleader || is_comrade?(m.user) == true
      if text == "add"
        open('ignored.txt', 'a') do |f|
          f.puts "#{who}"
        end
        m.reply Format("Added %s to %s." % [Format(:green, "#{who}"), Format(:bold, :red, "ignored")])
      elsif text == "del"
        system("sed -i '/#{who}/d' ignored.txt")
        m.reply Format("Removed %s from %s." % [Format(:green, "#{who}"), Format(:bold, :red, "ignored")])
      else
        m.reply Format(:bold, :red, "ERROR:") + " Invalid command."
      end
    else
      m.reply Format("%s %s isn't a comrade." % [Format(:bold, :red, "DENIED:"), Format(:green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to see stuff." % [Format(:bold, :blue, ":comrades view"), Format(:bold, :red, ":ignored view")])
    end
  end

  on :message, ":ignored view" do |m|
    ignView = File.open("#{$accesslvls[1]}").map(&:chomp).join(", ")
    m.reply "I am ignoring " + Format(:bold, :red, ignView)
  end

  # Things relevant to 3pasta.

  on :message, /;-;/ do |m|
    unless is_ignored?(m.user)
      m.reply Format("%s %s" % [Format(:purple, "don't cry, #{m.user.nick}..."), Format(:red, "<333")])
    end
  end

  on :message, "^" do |m|
    unless is_ignored?(m.user)
      colorsArray = [:aqua, :blue, :green, :lime, :orange, :pink, :red, :purple, :teal, :silver, :royal]
      textArray = [:bold, :italic, :reverse, :underline]
      m.reply Format(colorsArray.sample, textArray.sample, "can confirm")
    end
  end

  on :message, /\[(.+)\]/ do |m, text|
    unless is_ignored?(m.user)
      m.reply Format(:bold, :red, "[" + text.upcase + " INTENSIFIES]")
    end
  end
end

bot.start
