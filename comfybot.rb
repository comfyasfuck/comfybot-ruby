require 'cinch'
require 'cinch/plugins/identify'
require 'open-uri'
require 'nokogiri'
require 'cgi'

$admins = "admins.txt"
$comrades = "comrades.txt"
$ignored = "ignored.txt"

bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.rizon.net"
    c.channels = ["#pasta"]
    c.nick = "comfybot"
    c.verbose = true
    c.messages_per_second = 0.5
    c.plugins.plugins = [Cinch::Plugins::Identify]
    c.plugins.options[Cinch::Plugins::Identify] = {
      :password => "loldongs",
      :type => :nickserv,
    }
  end

  helpers do
    def is_admin?(user)
      system("grep #{user.nick} admins.txt")
    end

    def is_comrade?(user)
      system("grep #{user.nick} comrades.txt")
    end

    def is_ignored?(user)
      system("grep #{user.nick} ignored.txt")
    end

    def google(query)
      url = "http://www.google.com/search?q=#{CGI.escape(query)}"
      res = Nokogiri.parse(open(url).read).at("h3.r")
      title = res.text
      link = res.at('a')[:href]
      desc = res.at("./following::div").children.first.text
    rescue
      "No results found."
    else
      result = "#{title} - #{desc}"
      result.sub!("CachedSimilar", "")
      result.sub!("Cached", "")
      CGI.unescape_html result
    end

    def shorten(url)
      url = open("http://tinyurl.com/api-create.php?url=#{URI.escape(url)}").read
      url == "Error" ? nil : url
    rescue OpenURI::HTTPError
      nil
    end
  end

  # Basic bot shit; join, part, send, bots, etc.

  on :message, ".bots" do |m|
    unless is_ignored?(m.user)
      m.reply "Reporting in! [Ruby] Do " + Format(:bold, :purple, ":info") + " for cool stuff."
    end
  end

  on :message, ":info" do |m|
    unless is_ignored?(m.user)
      m.reply "I'm comfybot, comfy's bot. " + Format(:bold, :teal, "https://github.com/comfyasfuck/comfybot-ruby")
      m.reply "If you wanna b a comrade, ask comrade comfy. Do " + Format(:bold, :blue, ":comrades") + " to see the list."
    end
  end

  on :message, /:join (.+)/ do |m, channel|
    if is_admin?(m.user) == true || is_comrade?(m.user) == true
      bot.join(channel)
      unless m.user.nick == "comfyasfuck"
        User("comfyasfuck").send "I've joined #{channel} per #{m.user.nick}'s request."
      end
    else
      m.reply Format("%s %s is not priv." % [Format(:bold, :red, "ERROR:"), Format(:italic, :green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to view lists." % [Format(:bold, :blue, ":comrades"), Format(:bold, :red, ":ignored")])
    end
  end

  on :message, /:part (.+)/ do |m, channel|
    channel = channel || m.channel
    if is_admin?(m.user) == true || is_comrade?(m.user) == true
      if channel
        bot.part(channel)
      end
      unless m.user.nick == "comfyasfuck"
        User("comfyasfuck").send "I've parted from #{m.channel} per #{m.user.nick}'s request."
      end
    else
      m.reply Format("%s %s is not priv." % [Format(:bold, :red, "ERROR:"), Format(:italic, :green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to view lists." % [Format(:bold, :blue, ":comrades"), Format(:bold, :red, ":ignored")])
    end
  end

  on :message, /:send (.+?) (.+)/ do |m, who, text|
    if is_admin?(m.user) == true || is_comrade?(m.user) == true
      unless who == "comfybot"
        Channel(who).send text
      end
    else
      m.reply Format("%s %s is not priv." % [Format(:bold, :red, "ERROR:"), Format(:italic, :green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to view lists." % [Format(:bold, :blue, ":comrades"), Format(:bold, :red, ":ignored")])
    end
  end

  on :message, /:google (.+)/ do |m, query|
    unless is_ignored?(m.user)
      m.reply google(query)
    end
  end

  on :message, /:shorten (.+)/ do |m, text|
    unless is_ignored?(m.user)
      if text.include? "http" and text.include? "." and text.include? "//"
        m.reply shorten(text)
      else
        m.reply Format(:bold, :red, "GIVE ME AN ACTUAL FACTUAL URL NEXT TIME, FUCKOOOOOOO.")
      end
    end
  end

  # Sekrit botadmin spy stuff.

  on :message, /comfy / do |m|
    User("comfyasfuck").send "'comfy' was mentioned in #{m.channel} by #{m.user.nick}."
  end

  # Add and remove users from lists.

  on :message, /:comrades (.+?) (.+)/ do |m, who, text|
    if is_admin?(m.user) == true
      if text == "add"
        open('comrades.txt', 'a') do |f|
          f.puts "#{who}"
        end
        m.reply Format("Added %s to %s." % [Format(:green, "#{who}"), Format(:bold, :blue, "comrades")])
      elsif text == "del"
        system("sed -i '/#{who}/d' comrades.txt")
        m.reply Format("Removed %s from %s." % [Format(:green, "#{who}"), Format(:bold, :blue, "comrades")])
      else
        m.reply "Not a valid command."
      end
    end
  end

  on :message, /:admins (.+?) (.+)/ do |m, who, text|
    if is_admin?(m.user) == true
      if text == "add"
        open('admins.txt', 'a') do |f|
          f.puts "#{who}"
        end
        m.reply Format("Added %s to %s." % [Format(:green, "#{who}"), Format(:bold, :green, "admins")])
      elsif text == "del"
        system("sed -i '/#{who}/d' admins.txt")
        m.reply Format("Removed %s from %s." % [Format(:green, "#{who}"), Format(:bold, :green, "admins")])
      else
        m.reply "Not a valid command."
      end
    end
  end

  on :message, /:ignored (.+?) (.+)/ do |m, who, text|
    if is_admin?(m.user) == true
      if text == "add"
        open('ignored.txt', 'a') do |f|
          f.puts "#{who}"
        end
        m.reply Format("Added %s to %s." % [Format(:green, "#{who}"), Format(:bold, :red, "ignored")])
      elsif text == "del"
        system("sed -i '/#{who}/d' ignored.txt")
        m.reply Format("Removed %s from %s." % [Format(:green, "#{who}"), Format(:bold, :red, "ignored")])
      else
        m.reply "Not a valid command."
      end
    end
  end

  # Stupid shit for 3pasta.

  on :message, /;-;/ do |m|
    unless is_ignored?(m.user)
      m.reply Format("%s %s" % [Format(:purple, "d-don't cry, #{m.user.nick}..."), Format(:red, "<333")])
    end
  end

  on :message, "^" do |m|
    unless is_ignored?(m.user)
      colorsArray = [:aqua, :blue, :green, :lime, :orange, :pink, :red, :purple, :teal, :silver, :royal]
      textArray = [:bold, :italic, :reverse, :underline]
      m.reply Format(colorsArray.sample, textArray.sample, "can confirm")
    end
  end

  on :message, /:tell (.+)/ do |m, text|
    unless is_ignored?(m.user)
      text2 = text.lstrip.rstrip.upcase
      m.reply Format(:bold, :red, "YOU LITTLE STUPID ASS " + text2.upcase + " I AINT FUCKIN WHICHUUUUU")
    end
  end

  on :message, /\[(.+)\]/ do |m, text|
    unless is_ignored?(m.user)
      m.reply Format(:bold, :red, "[" + text.upcase + " INTENSIFIES]")
    end
  end

  on :message, /:spam (.+?) (.+)/ do |m, who, text|
    sizeHor = who.split('x',2).first.to_i
    sizeVer = who.split('x',2).last.to_i
    whileNum = 1
    spamText = "#{text} ".lstrip.rstrip + " "

    colorsArray = [:aqua, :blue, :green, :lime, :orange, :pink, :red, :purple, :teal, :silver, :royal]
    textArray = [:bold, :italic, :reverse, :underline]

    if is_admin?(m.user) || is_comrade?(m.user)
      while whileNum <= sizeHor
	if whileNum == sizeHor
	  whileNum = 1
	  while whileNum <= sizeVer
	    m.reply Format(colorsArray.sample, textArray.sample, spamText.upcase)
	    whileNum += 1
	  end
	end
	whileNum += 1
	spamText = spamText + "#{text} ".lstrip.rstrip + " "
      end
    else
      m.reply Format("%s %s is not priv." % [Format(:bold, :red, "ERROR:"), Format(:italic, :green, "#{m.user.nick}")])
      m.reply Format("Run %s or %s to view lists." % [Format(:bold, :blue, ":comrades"), Format(:bold, :red, ":ignored")])
    end
  end

  on :message, ":admins" do |m|
    adminsJoin = File.open("admins.txt").map(&:chomp).join(", ")
    m.reply "My current admin is " + Format(:bold, :green, adminsJoin)
  end

  on :message, ":comrades" do |m|
    comradesJoin = File.open("comrades.txt").map(&:chomp).join(", ")
    m.reply "My comrades are " + Format(:bold, :blue, comradesJoin)
  end

  on :message, ":ignored" do |m|
    ignoredJoin = File.open("ignored.txt").map(&:chomp).join(", ")
    m.reply "I am ignoring " + Format(:bold, :red, ignoredJoin)
  end
end

bot.start
