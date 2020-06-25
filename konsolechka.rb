# frozen_string_literal: false

require 'json'

require 'cinch'
require 'pry'
require 'geoip'
require 'open_uri_redirections'
require 'open3'
require 'htmlentities'
require 'mechanize'
require 'action_view'
require 'addressable/uri'
require 'simpleidn'
require 'twitter'
require 'sypex_geo'
require 'socket'
require 'fastimage'
require 'google_url_shortener'
require 'i18n'
require 'russian'
require 'yaml'
require 'sinatra'
require 'pp'
require 'pry'
require 'date'
require 'awesome_print'
require 'google/cloud'
require 'cgi'
require 'google/cloud/translate'
include ActionView::Helpers::DateHelper
include ActionView::Helpers::NumberHelper
require 'datagrid'
# require "pidfile"
require 'memory_profiler'

# PidFile.new(:piddir => '/var/run/konsolechka', :pidfile => "konsolechka.pid")


# class PidorsGrid
#  include Datagrid
#
#
#  scope do
#  $pidors[:id]
#  end
#
#  #
#  # Filters
#  #
#
#  filter(:nick, :string, :multiple => ',')
#  filter(:host, :string)
#  filter(:pidor_status, :xboolean)
#  column_names_filter(:header => "Extra Columns", checkboxes: true)
#
#  #
#  # Columns
#  #
#
#  column(:nick, :mandatory => true)
#  column(:host, :mandatory => true)
#  column(:pidor_status, :mandatory => true)
#
#
#
#
# end
#
# class PidorsController < ApplicationController
#
#  def index
#    @pidors_grid = PidorsGrid.new(params[:pidors_grid]) do |scope|
#      scope.page(params[:page])
#    end
#  end
# end
#

# Веб-сервер статистики игры в пидора
class PidorApp < Sinatra::Application

  configure do
    set :threaded, true
    set :traps, false
  end

  set :bind, '0.0.0.0'
  set :port, 4567
  disable :raise_errors
  set :raise_errors, false
  set :show_exceptions, false
  disable :show_exceptions
  get '/pidor/' do
    redirect "/pidor/#{$game_session_number}/"
  end

  get '/help/' do
    erb :help
  end


  get '/pidor/:session_number/' do
    erb :index
  end
end


I18n.default_locale = :ru
I18n.locale = :ru

# ОБЩИЕ МЕТОДЫ

$translate = Google::Cloud::Translate.new(
  version: :v2,
  project_id: 'konsol-12345',
  credentials: '/konsolechka/google-translate.json'
  )


$twitter_topics = ['your-twitter-id', 'пердолик', 'пердолики', '2ch.hk', '@your-twitter-id', 'Пердолики']
$current_twitter_topics = []
$twi = Twitter::REST::Client.new do |config|
  config.consumer_key        = 'Your_KEY'
  config.consumer_secret     = 'Your_SECRET'
  config.access_token        = 'Your_ACCESS_TOKEN'
  config.access_token_secret = 'Your_TOKEN_SECRET'
end

$twis ||= Twitter::Streaming::Client.new do |config|
  config.consumer_key        = 'Your_KEY'
  config.consumer_secret     = 'Your_SECRET'
  config.access_token = 'Your_ACCESS_TOKEN'
  config.access_token_secret = 'Your_TOKEN_SECRET'
end


Thread.new do
  sleep 20
  loop do
    sleep 20 and next unless $current_twitter_topics.join(',') != $twitter_topics.join(',')

    begin
      $current_twitter_topics = $twitter_topics
      puts "\n (пере)подключаем объект твиттора с темами: #{$twitter_topics.join(',')}\n"
      $twis.filter(track: $twitter_topics.join(',')) do |tw|
        if tw.is_a?(Twitter::Tweet) && tw.user.screen_name != 'your-twitter-id'
          Channel('#konsolechka').send("Пидр https://twitter.com/#{tw.user.screen_name}/status/#{tw.id} из твитора говорит: #{tw.text}")
        end
      end
      $twis.user(replies: 'all') do |object|
        case object
        when Twitter::Tweet
          if object.is_a?(Twitter::Tweet) && object.user.screen_name != 'your-twitter-id'
            Channel('#konsolechka').send("Пидр https://twitter.com/#{object.user.screen_name}/status/#{object.id} из твитора говорит: #{object.text}")
          end
        when Twitter::DirectMessage
          if object.is_a?(Twitter::DirectMessage)
            Channel('#konsolechka').send("Пидр @#{object.sender.sender_screen_name} отправил нам в личку твитора: #{object.text}")
          end
        end
      end
    end
  end
end


Google::UrlShortener::Base.api_key = 'YOUR_API_KEY'
Google::UrlShortener::Base.log = $stdout

class String
  def zamena_mestoimeniy
    self.strip.gsub(/\s+/, ' ').gsub(/\bне нельзя\b/i, 'можноÜÜÜ').gsub(/\bне можно\b/i, 'нельзяÜÜÜ').gsub(/\bмне\b/, 'тебеÜÜÜ').gsub(/\bя\b/, 'тыÜÜÜ').gsub(/\bЯ\b/, 'ТыÜÜÜ').gsub(/\bмы\b/, 'выÜÜÜ').gsub(/\bМы\b/, 'ВыÜÜÜ').gsub(/\bменя\b/, 'тебяÜÜÜ').gsub(/\bМеня\b/, 'ТебяÜÜÜ').gsub(/\bнас\b/, 'васÜÜÜ').gsub(/\bНас\b/, 'ВасÜÜÜ').gsub(/\bмне\b/, 'тебеÜÜÜ').gsub(/\bМне\b/, 'ТебеÜÜÜ').gsub(/\bнам\b/, 'вамÜÜÜ').gsub(/\bНам\b/, 'ВамÜÜÜ').gsub(/\bмной\b/, 'тобойÜÜÜ').gsub(/\bМной\b/, 'ТобойÜÜÜ').gsub(/\bмой\b/, 'твойÜÜÜ').gsub(/\bМой\b/, 'ТвойÜÜÜ').gsub(/\bмоя\b/, 'твояÜÜÜ').gsub(/\bМоя\b/, 'ТвояÜÜÜ').gsub(/\bмое\b/, 'твоеÜÜÜ').gsub(/\bМое\b/, 'ТвоеÜÜÜ').gsub(/\bмоё\b/, 'твоёÜÜÜ').gsub(/\bМоё\b/, 'ТвоёÜÜÜ').gsub(/\bмои\b/, 'твоиÜÜÜ').gsub(/\bМои\b/, 'ТвоиÜÜÜ').gsub(/\bмоего\b/, 'твоегоÜÜÜ').gsub(/\bМоего\b/, 'ТвоегоÜÜÜ').gsub(/\bмоей\b/, 'твоейÜÜÜ').gsub(/\bМоей\b/, 'ТвоейÜÜÜ').gsub(/\bмоих\b/, 'твоихÜÜÜ').gsub(/\bМоих\b/, 'ТвоихÜÜÜ').gsub(/\bмоему\b/, 'твоемуÜÜÜ').gsub(/\bМоему\b/, 'ТвоемуÜÜÜ').gsub(/\bмою\b/, 'твоюÜÜÜ').gsub(/\bМою\b/, 'ТвоюÜÜÜ').gsub(/\bмоим\b/, 'твоимÜÜÜ').gsub(/\bМоим\b/, 'ТвоимÜÜÜ').gsub(/\bмоими\b/, 'твоимиÜÜÜ').gsub(/\bМоими\b/, 'ТвоимиÜÜÜ').gsub(/\bмоём\b/, 'твоёмÜÜÜ').gsub(/\bМоём\b/, 'ТвоёмÜÜÜ').gsub(/\bмоем\b/, 'твоемÜÜÜ').gsub(/\bМоем\b/, 'ТвоемÜÜÜ').gsub(/\bнаш\b/, 'вашÜÜÜ').gsub(/\bНаш\b/, 'ВашÜÜÜ').gsub(/\bнаша\b/, 'вашаÜÜÜ').gsub(/\bНаша\b/, 'ВашаÜÜÜ').gsub(/\bнаше\b/, 'вашеÜÜÜ').gsub(/\bНаше\b/, 'ВашеÜÜÜ').gsub(/\bнаши\b/, 'вашиÜÜÜ').gsub(/\bНаши\b/, 'ВашиÜÜÜ').gsub(/\bты\b/, 'яÜÜÜ').gsub(/\bТы\b/, 'ЯÜÜÜ').gsub(/\bвы\b/, 'мыÜÜÜ').gsub(/\bВы\b/, 'МыÜÜÜ').gsub(/\bтебя\b/, 'меняÜÜÜ').gsub(/\bТебя\b/, 'МеняÜÜÜ').gsub(/\bвас\b/, 'насÜÜÜ').gsub(/\bВас\b/, 'НасÜÜÜ').gsub(/\bтебе\b/, 'мнеÜÜÜ').gsub(/\bТебе\b/, 'МнеÜÜÜ').gsub(/\bвам\b/, 'намÜÜÜ').gsub(/\bВам\b/, 'НамÜÜÜ').gsub(/\bтобой\b/, 'мнойÜÜÜ').gsub(/\bТобой\b/, 'МнойÜÜÜ').gsub(/\bтвой\b/, 'мойÜÜÜ').gsub(/\bТвой\b/, 'МойÜÜÜ').gsub(/\bтвоя\b/, 'мояÜÜÜ').gsub(/\bТвоя\b/, 'МояÜÜÜ').gsub(/\bтвое\b/, 'моеÜÜÜ').gsub(/\bТвое\b/, 'МоеÜÜÜ').gsub(/\bтвоё\b/, 'моёÜÜÜ').gsub(/\bТвоё\b/, 'МоёÜÜÜ').gsub(/\bтвои\b/, 'моиÜÜÜ').gsub(/\bТвои\b/, 'МоиÜÜÜ').gsub(/\bтвоего\b/, 'моегоÜÜÜ').gsub(/\bТвоего\b/, 'МоегоÜÜÜ').gsub(/\bтвоей\b/, 'моейÜÜÜ').gsub(/\bТвоей\b/, 'МоейÜÜÜ').gsub(/\bтвоих\b/, 'моихÜÜÜ').gsub(/\bТвоих\b/, 'МоихÜÜÜ').gsub(/\bтвоему\b/, 'моемуÜÜÜ').gsub(/\bТвоему\b/, 'МоемуÜÜÜ').gsub(/\bтвою\b/, 'моюÜÜÜ').gsub(/\bТвою\b/, 'МоюÜÜÜ').gsub(/\bтвоим\b/, 'моимÜÜÜ').gsub(/\bТвоим\b/, 'МоимÜÜÜ').gsub(/\bтвоими\b/, 'моимиÜÜÜ').gsub(/\bТвоими\b/, 'МоимиÜÜÜ').gsub(/\bтвоём\b/, 'моёмÜÜÜ').gsub(/\bТвоём\b/, 'МоёмÜÜÜ').gsub(/\bтвоем\b/, 'моемÜÜÜ').gsub(/\bТвоем\b/, 'МоемÜÜÜ').gsub(/\bваш\b/, 'нашÜÜÜ').gsub(/\bВаш\b/, 'НашÜÜÜ').gsub(/\bваша\b/, 'нашаÜÜÜ').gsub(/\bВаша\b/, 'НашаÜÜÜ').gsub(/\bваше\b/, 'нашеÜÜÜ').gsub(/\bВаше\b/, 'НашеÜÜÜ').gsub(/\bваши\b/, 'нашиÜÜÜ').gsub(/\bВаши\b/, 'НашиÜÜÜ').gsub(/ÜÜÜ/, '').strip.gsub(/\s+/, ' ').gsub(/\s+([,\.!])/, '\1').gsub(%r{([,\.!])(?![\s\d]+)(?![$/])}, '\1').gsub(/(\d+),(\d+)/, '\1.\2').gsub(/(\d+)\*(\d+)/i, '\1×\2').gsub(/(\d+)Х(\d+)/i, '\1×\2').gsub(/(\d+)х(\d+)/i, '\1×\2').gsub(/(\d+)x(\d+)/i, '\1×\2').gsub(/"([\p{Cyrillic}|\s|0-9|×]*)"/m, '«\1»').gsub(/« /, '«').gsub(/ »/, '»')
  end

  def kapitalizirovat_russky
    self.strip.gsub(/\s+/, ' ').gsub(/\s+([,\.!])/, '\1').gsub(%r{([,\.!])(?![\s\d]+)(?![$/])}, '\1').gsub(/(\d+),(\d+)/, '\1.\2').gsub(/(\d+)\*(\d+)/i, '\1×\2').gsub(/(\d+)Х(\d+)/i, '\1×\2').gsub(/(\d+)х(\d+)/i, '\1×\2').gsub(/(\d+)x(\d+)/i, '\1×\2').gsub(/"([\p{Cyrillic}|\s|0-9|×]*)"/m, '«\1»').gsub(/« /, '«').gsub(/ »/, '»').gsub(/^[а-я]/) {|s| s[0].to_s.capitalize }
  end

  def ubernation_days
    if (Time.new.wday == 3) && (Time.new.day < 7)
      translation = $translate.translate self, to: 'uk'
      CGI.unescapeHTML(translation.text).gsub(/ \.\.\./, '…')
    elsif (Time.new.wday == 4) && (Time.new.day < 7)
      translation = $translate.translate self, to: 'be'
      CGI.unescapeHTML(translation.text).gsub(/ \.\.\./, '…')
    else
      self.gsub(/\.\.\./, '…')
    end
  end

  def posyl_v_googl
    Google::UrlShortener.shorten!(self)
  end

  def ukorachivanie_ssylok
    self.gsub(%r{((?:http|https)://\S+)}) do |link|
      if link.length > 120
        # "[#{link.posyl_v_googl}] #{link}"
        link
      else
        link
      end
    end
  end
end

k = Cinch::Bot.new do


  Thread.new do
    PidorApp.run!
    exit
  end

  # binding.pry
  configure do |c|
    c.server = 'chat.freenode.net'
    c.port = '6697'
    c.channels = ['#konsolechka']
    c.nick = 'Konsolka_oss'
    c.ssl.use = true
    c.ssl.verify = true
    c.user = 'konsolka_oss'
    c.realname = '(\\/)'
    c.message_split_start = '…'
    c.message_split_end = '…'
  end


  callback.instance_eval do
    @replied = true
    @lentach = true
    @eval_allowed_users = %w[unaffiliated/your_freenode_host]
    @ignored_users = []
    @ignored_nicks = %w[Maj_Petrenko Konsolechka Konsolechka LzheKonsolka yalb coinBot AnimeChan Qubick Sopel ChirnoBot urp]
    @vatniks = %w[]
    $game_started = false
    # @tells ||= Hash.new{ |h, k| h[k] = [] }.merge JSON.parse(File.read('tells.txt'))

    @otv = File.readlines('otv.txt').map(&:chomp)

    def t_m
      @last_ment ||= 0; $twi.mentions_timeline(count: 3).select { |e| e.created_at.to_i > @last_ment }.reverse.tap { |e| unless e.empty?
                                                                                                                           @last_ment = e.last.created_at.to_i
                                                                                                                         end }.each { |t| Channel('#konsolechka').send "@#{t.user.screen_name}: #{t.text}" }
    end

    Thread.new do
      loop do
        # @last_ment||=0;$twi.mentions_timeline(count: 3).select{|e|e.created_at.to_i > @last_ment}.reverse.tap{|e|@last_ment=e.last.created_at.to_i unless e.empty?}.each{|t|Channel("#konsolechka").send "@#{t.user.screen_name}: #{t.text}"}
        t_m
        sleep 600
      end
    end

    @pornostories = File.read('pornostories.txt').split("\r\n\r\n\r\n\r\n")

    def tts(text_orig, voice = 'nikolai', speed = 0)
      randyoba = Dir['public/*'].sample
      tts_out = "./tmp/file#{Array.new(20) { ('a'..'z').to_a.sample }.join}.wav"
      youtube_title = text_orig[0..99].gsub(/[^а-яА-Яa-zA-Z\- 0-9]/i, '')

      `wget -O #{tts_out} "http://8.8.8.8:5000/balabolka?text=#{text_orig}&voice=#{voice}&speed=#{speed}"`
      `ffmpeg -loop 1 -i #{randyoba} -i #{tts_out} -shortest -y ./tmp/video.webm`

      'https://www.youtube.com/watch?v=' + `youtube-upload -t '#{text_orig[0..99]}' ./tmp/video.webm`
    end

    def gi(t)
      t = URI.escape(t)
      link_check = JSON.parse(
        open("https://www.googleapis.com/customsearch/v1?q=#{t}&cx=YOUR_CX_KEY&searchType=image&key=YOUR_KEY&num=1&safe=off").read
      ).dig('items', 0, 'link')
      if link_check.nil?

        'К сожалению, по вашему запросу ничего не найдено!'.ubernation_days
      else

        link_result = URI(link_check)


          link_check = link_result.scheme + '://' + SimpleIDN.to_unicode(link_result.host)

          unless link_result.path.nil?
            link_check = link_check + CGI.unescape(link_result.path).gsub(/\s/, '%20')
          end

          unless link_result.query.nil?
            link_check = link_check + '?' + CGI.unescape(link_result.query).gsub(/\s/, '%20')
          end

          unless link_result.fragment.nil?
            link_check = link_check + '#' + CGI.unescape(link_result.fragment).gsub(/\s/, '%20')
          end

          link_final = if link_check.length > 100
            # link_final = "["+link_check.posyl_v_googl+"] "+link_check
            link_check
          else
            link_check
                       end
          link_final
    end
    end

    def praz
      praz_date = Time.now.to_s
      praz_date = DateTime.parse(praz_date).strftime('%Y-%-m-%-d')
      Nokogiri.parse(open('https://www.calend.ru/holidays/' + praz_date + '/').read).search('div.caption>span.title>a').map(&:text)
    end

    def kmp
      Nokogiri.parse(open('http://killpls.me/random/', allow_redirections: :all).read).search('#stories')[0].search('div.row > div.col-xs-12').map(&:text)[0].strip.gsub(/\s+/, ' ').ubernation_days
    end
  end

   on(:message, /Консолька, дистрибутивы/) {|m| a = Nokogiri.parse(open('https://distrowatch.com/').read); m.reply a.search('.phr2').first(10).zip(a.search('.phr3')).map {|e| "#{e[0].text.ubernation_days}: #{e[1].text.ubernation_days}" }.join("\n") }
  
   on(:message, /^(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*совет/i) do |m|
     unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
       m.reply HTMLEntities.new.decode(JSON.parse(open('http://fucking-great-advice.ru/api/random').read)['text']).gsub(/\sблять\s/, ', блять, ').ubernation_days
     end
  end

  # on(:message,/^!lentach/){|m|m.reply @last_lentach_post}

  on(:message, /^!twi\s*$/) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      m.reply 'http://twitter.com/YOUR_TWITTER_ID'
    end
  end


  on(:message, /^!tr (.+)/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

      n = m.message

      if n =~ /^!tr (.+)\s+([a-z]{1,3})\s*$/i
        n1, n2 = n.match(/^!tr (.+)\s+([a-z]{1,3})\s*$/i)&.captures

      else


        n1 = n.match(/^!tr (.+)\s*$/i)&.captures&.first

        if n1.match?(/.*(\p{Cyrillic}).*/i)
          n2 = 'en'
        else
          n2 = 'ru'
        end

      end

      translation = $translate.translate n1, to: n2
      translation = CGI.unescapeHTML(translation.text).gsub(/ \.\.\./, '…')

      m.replytranslation.to_s

    end
  end



  on(:message, /!gt (>[^>]+.*)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      r = n.scan(/>[^>]+/)
      if r.length > 3
        answ = 'Слишком много гринтекста!'.ubernation_days
      else
        answ = ''
       unless r.empty?
         r.map do |e|
          answ = answ + "\00303" + e.ubernation_days.gsub(/> /, '>') + "\n"
         end
       end
      end
      m.reply answ
    end
  end

  on(:message, /!gty (>[^>]+.*)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      r = n.scan(/>[^>]+/)
      if r.length > 3
        answ = 'Слишком много гринтекста!'.ubernation_days
      else
        unless r.empty?
         answ = "\00303>#{Time.now.year}\n"
         r.map do |e|
 
          answ = answ + "\00303" + e.ubernation_days.gsub(/> /, '>') + "\n"
         end
        end
      end
      m.reply answ
    end
  end

  on(:message, /^!help/) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if $no_highlight_nicks.include?(m.user.nick)
        m.reply "#{m.user.nick.dup.insert(1, '‍')}, https://your-domain.ga/help/"
      else
        m.reply "#{m.user.nick}, https://your-domain.ga/help/"
      end
    end
  end

  on(:message, /^.*ACTION погладил (?:Konsolech|Консол)(?:ь|еч|)(?:ka|ку).*/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      @gladit_variants = ['извернулась и цапнула пидора #NICKNAME# за руку!', 'заурчала', 'слегка мурлыкнула', 'отскочила и зашипела на #NICKNAME#', 'посмотрела на #NICKNAME# как на пустое место', 'свернулась в клубочек', 'продолжила хранить молчание', 'нажаловалась на домогательства мочератору']
      m.action_reply((@gladit_variants.sample.ubernation_days).to_s.gsub(/#NICKNAME#/, (m.user.nick).to_s))
    end
  end

  on(:message, /!gi (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if n.match?(/.* ?> ?[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*/i)
        puts "Матч по нику\n"
        nick = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[2]
        puts "Ник #{nick}\n"
        if m.channel.users.map {|e| e[0].nick }.include?(nick)
          to_find = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[1]
          m.reply nick + ': ' + gi(to_find)
        else
          m.reply gi(n)
        end
      else
        m.reply gi(n)
      end
    end
  end


  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка), праздники/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      m.safe_reply praz.map { |x| x.ubernation_days }
    end
  end

  # on(:message, /(?:!(?:kmp|кмп)|%(?:кмп|kmp))/i) do |m|
  #   unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
  #     m.reply kmp
  #   end
  # end

  on(:message, /^!addotv (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      @otv << n
      m.channel.action('добавила!'.ubernation_days)
    end
  end


  on(:message, /^(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка), когда (.+)\?/i) do |m, _n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

      if $no_highlight_nicks.include?(m.user.nick)

        m.reply "#{m.user.nick.dup.insert(1, '‍')}, #{@otv.sample.ubernation_days}"
      else
        m.reply "#{m.user.nick}, #{@otv.sample.ubernation_days}"
      end
    end
  end


  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s* найди (.+)/i) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if (user = User(n.strip)).unknown?
        m.reply "404: юзер #{n} не найден)".ubernation_days
      else
        h = user.host.match?(/kiwiirc/i) ? user.host.match(/\d+\.\d+\.\d+\.\d+/)[0] : user.host
        h = h[/\d+-\d+-\d+-\d+/] ? h[/\d+-\d+-\d+-\d+/].tr('-', '.') : h
        db = SypexGeo::Database.new('./SxGeoCity.dat')
        location = db.query(h)
        m.reply "#{location.country} :: #{location.city}".ubernation_days
      end
    end
  end

  on(:message, /^!twi (.+)/) do |m, n|
    break unless m.channel

    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      twi_length = n.gsub(%r{(?:http|https)://\S+}, '').gsub(/  /, ' ')
      if twi_length.length > 280
        final_answer = 'Слишком длинное сообщение (>280 символов). Вы ебанули ' + twi_length.length.to_s + ' символов. Укоротите ваше говно на ' + (twi_length.length - 280).to_s + ' буков.'
        m.reply final_answer.ubernation_days
      else
        unless @vatniks.include?(m.user.nick)
          if n.match?(/^-r(\d+)\s+/) || n.match?(/^-r\s*(\d+)\s+/)
            status_id = n.match(/^-r\s*(\d+)\s+/)[1]
            status_text = n.match(/^-r\s*\d+\s+(.+)/)[1]
            $twi.update(status_text, in_reply_to_status_id: status_id, auto_populate_reply_metadata: 'true')
          else
            $twi.update(n)
          end
        end
        m.channel.action 'твитнула!'.ubernation_days
      end
    end
  end

  on(:message, /^!tts (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if !@lasttts || Time.now - @lasttts >= 30
        m.reply tts(n, 'nikolai', -2)
        @lasttts = Time.now
      end
    end
  end

  on(:message, /^!song (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      m.channel.action('добавила песенку!') if open("http://8.8.8.8:5000/musicqueue/#{n}")
    end
  end

  on(:message, /^(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*историю/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      m.reply @pornostories.sample.ubernation_days
    end
  end

  on(:message, /^!nick (.+)/) do |m, n|
    break unless m.user.host.match?(%r{^unaffiliated/yourhostname$}i)

    k.nick = n
    User('NickServ').send("identify #{k.password}")
  end

  on(:message, /(?:!(?:google|g)|%d) (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if n.match?(/.* ?> ?[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*/i)
        puts "Матч по нику\n"
         nick = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[2]
         puts "Ник #{nick}\n"
         if m.channel.users.map {|e| e[0].nick }.include?(nick)
           to_find = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[1]
             puts "To find #{to_find}\n"
             to_find = URI.encode(to_find)
             resp = JSON.parse(open("https://www.googleapis.com/customsearch/v1?q=#{to_find}&cx=Your_CX&num=1&key=Your_Key&safe=off").read)
             if resp.dig('items', 0, 'link').nil?
   
               m.reply( nick + ': ' + 'К сожалению, по вашему запросу ничего не найдено!'.ubernation_days)
               next
   
             end
             link_result = URI(resp.dig('items', 0, 'link'))


             link_check = link_result.scheme + '://' + SimpleIDN.to_unicode(link_result.host)

             unless link_result.path.nil?
               link_check = link_check + CGI.unescape(link_result.path).gsub(/\s/, '%20')
             end

             unless link_result.query.nil?
               link_check = link_check + '?' + CGI.unescape(link_result.query).gsub(/\s/, '%20')
             end

             unless link_result.fragment.nil?
               link_check = link_check + '#' + CGI.unescape(link_result.fragment).gsub(/\s/, '%20')
             end


          # puts URI.decode(resp.dig('items', 0, 'link'))

             link_final = if link_check.length > 100
               # link_final = "["+link_check.posyl_v_googl+"] "+link_check
               link_check
             else
               link_check
                          end
             res = nick + ': ' + resp.dig('items', 0, 'title').ubernation_days + ' - ' + link_final
          # out = URI::decode(URI::decode(res['url'].force_encoding("utf-8"))).gsub(/ /, "%20")
          # m.reply "#{Sanitize.fragment(res['title'])}: #{out}"
             m.reply res
         else
          n = URI.encode(n)
             resp = JSON.parse(open("https://www.googleapis.com/customsearch/v1?q=#{n}&cx=Your_CX&num=1&key=Your_Key&safe=off").read)
             if resp.dig('items', 0, 'link').nil?
   
               m.reply'К сожалению, по вашему запросу ничего не найдено!'.ubernation_days
               next
   
             end


             link_result = URI(resp.dig('items', 0, 'link'))


             link_check = link_result.scheme + '://' + SimpleIDN.to_unicode(link_result.host)

             unless link_result.path.nil?
               link_check = link_check + CGI.unescape(link_result.path).gsub(/\s/, '%20')
             end

             unless link_result.query.nil?
               link_check = link_check + '?' + CGI.unescape(link_result.query).gsub(/\s/, '%20')
             end

             unless link_result.fragment.nil?
               link_check = link_check + '#' + CGI.unescape(link_result.fragment).gsub(/\s/, '%20')
             end


             puts URI.decode(resp.dig('items', 0, 'link'))
             link_final = if link_check.length > 100
               # link_final = "["+link_check.posyl_v_googl+"] "+link_check
               link_check
             else
               link_check
                          end
             res = link_final + ' - ' + resp.dig('items', 0, 'title').ubernation_days
          # out = URI::decode(URI::decode(res['url'].force_encoding("utf-8"))).gsub(/ /, "%20")
          # m.reply "#{Sanitize.fragment(res['title'])}: #{out}"
             m.reply res
        end
      else
        puts "Нет матча по нику\n"
         n = URI.encode(n)
         resp = JSON.parse(open("https://www.googleapis.com/customsearch/v1?q=#{n}&cx=Your_CX&num=1&key=Your_Key&safe=off").read)
         puts "https://www.googleapis.com/customsearch/v1?q=#{n}&cx=Your_CX&num=1&key=Your_Key&safe=off"
         if resp.dig('items', 0, 'link').nil?

           m.reply'К сожалению, по вашему запросу ничего не найдено!'.ubernation_days
           next

         end

         link_result = URI(resp.dig('items', 0, 'link'))


         link_check = link_result.scheme + '://' + SimpleIDN.to_unicode(link_result.host)

         unless link_result.path.nil?
           link_check = link_check + CGI.unescape(link_result.path).gsub(/\s/, '%20')
         end

         unless link_result.query.nil?
           link_check = link_check + '?' + CGI.unescape(link_result.query).gsub(/\s/, '%20')
         end

         unless link_result.fragment.nil?
           link_check = link_check + '#' + CGI.unescape(link_result.fragment).gsub(/\s/, '%20')
         end


         link_final = if link_check.length > 100
           # link_final = "["+link_check.posyl_v_googl+"] "+link_check
           link_check
         else
           link_check
                      end
         res = link_final + ' - ' + resp.dig('items', 0, 'title').ubernation_days
        # out = URI::decode(URI::decode(res['url'].force_encoding("utf-8"))).gsub(/ /, "%20")
        # m.reply "#{Sanitize.fragment(res['title'])}: #{out}"
         m.reply res
      end
    end
  end

  on(:message, /!(?:yandex|y) (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

      a = Mechanize.new

      a.max_history = 1
      a.max_file_buffer = 65_535
      a.redirection_limit = 3
      a.idle_timeout = 1
      a.ignore_bad_chunking = true
      a.keep_alive = false
      a.open_timeout = 3
      a.read_timeout = 4
      a.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.3282.39 Safari/537.36 kons'

      if n.match?(/.* ?> ?[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*/i)
        puts "Матч по нику\n"
         nick = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[2]
         puts "Ник #{nick}\n"
         if m.channel.users.map {|e| e[0].nick }.include?(nick)
           to_find = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[1]
           a.get("https://yandex.ru/search/?text=#{to_find}")
           m.reply nick + ': ' + "#{a.page.search('.organic__title-wrapper > a')[0].text.ubernation_days} - #{a.page.search('.organic__title-wrapper > a')[0][:href]}"
         else
           a.get("https://yandex.ru/search/?text=#{n}")
           m.reply "#{a.page.search('.organic__title-wrapper > a')[0].text.ubernation_days} - #{a.page.search('.organic__title-wrapper > a')[0][:href]}"
         end
      else
        a.get("https://yandex.ru/search/?text=#{n}")
        m.reply "#{a.page.search('.organic__title-wrapper > a')[0].text.ubernation_days} - #{a.page.search('.organic__title-wrapper > a')[0][:href]}"
      end

    end
  end

  on(:message, /!ddg (.+)/) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if n.match?(/.* ?> ?[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*/i)
        puts "Матч по нику\n"
         nick = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[2]
         puts "Ник #{nick}\n"
         if m.channel.users.map {|e| e[0].nick }.include?(nick)
           to_find = n.match(/(.*) ?> ?([a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*)/i)[1]
             query = URI.escape(to_find)
             page = Nokogiri.parse(open("https://duckduckgo.com/html/?q=#{query}"))
             link_check = URI.decode(page.search('.results .web-result .result__a')[0]['href'].match(/&uddg=(.+)/)[1])
             result_url = if link_check.length > 100
               link_check
             else
               link_check
                          end
             result_text = page.search('.results .web-result .result__a')[0].text
             result = nick + ': ' + result_text.ubernation_days + ' - ' + result_url
             m.reply result
         else
           query = URI.escape(n)
             page = Nokogiri.parse(open("https://duckduckgo.com/html/?q=#{query}"))
             link_check = URI.decode(page.search('.results .web-result .result__a')[0]['href'].match(/&uddg=(.+)/)[1])
             result_url = if link_check.length > 100
               link_check
             else
               link_check
                          end
             result_text = page.search('.results .web-result .result__a')[0].text
             result = result_url + ' - ' + result_text.ubernation_days
             m.reply result
         end
      else
        query = URI.escape(n)
         page = Nokogiri.parse(open("https://duckduckgo.com/html/?q=#{query}"))
         link_check = URI.decode(page.search('.results .web-result .result__a')[0]['href'].match(/&uddg=(.+)/)[1])
         result_url = if link_check.length > 100
           link_check
         else
           link_check
                      end
         result_text = page.search('.results .web-result .result__a')[0].text
         result = result_url + ' - ' + result_text.ubernation_days
         m.reply result
      end
    end
  end

  on :message, /^>>/ do |m, _n|
    if @eval_allowed_users.include?(m.user.host)

      cmd = m.message.match(/>>(.+)/)[1]
      result = eval(cmd.strip)
      result.to_s.split("\n").length > 4 || result.to_s.length > 846 ? m.reply('>>>ERR: result is too long (>4 lines or >846 characters)') : m.reply(">>> #{result}")
    end
  end

  on :message, /^\s*(\S+)\s+соснул\?+/i do |m, nick|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if nick.match?(/кто/i)
        nick = m.channel.users.to_a.sample[0].nick
        sosnuvshy = nick == k.nick ? nil : nick
        if $no_highlight_nicks.include?(sosnuvshy)
          sosnuvshy ? m.reply("#{sosnuvshy.dup.insert(1, '‍')}, ты соснул!".ubernation_days) : m.channel.action('соснула!')

        else
          sosnuvshy ? m.reply("#{sosnuvshy}, ты соснул!".ubernation_days) : m.channel.action('соснула!')
        end

      else

        if $no_highlight_nicks.include?(nick)

          m.reply("#{nick.dup.insert(1, '‍')}#{rand > 0.5 ? ' ' : ' не '}соснул!".ubernation_days)
        else
          m.reply("#{nick}#{rand > 0.5 ? ' ' : ' не '}соснул!".ubernation_days)
        end
      end
    end
    if @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      m.reply('Ты соснул, мудила, ёпт!'.ubernation_days)
    end
  end

  on :message, /^\s*(\S+)\s+хохол\?+/i do |m, nick|
    begin
      host = User(nick).host.match(/\d+\.\d+\.\d+\.\d+/)[0]
      c = GeoIP.new('GeoLiteCity.dat').country(host).country_code2
      m.reply c == 'UA' ? "#{nick} хохол! Лови хохла!".ubernation_days : "#{nick} ни разу не хохол!".ubernation_days
    rescue StandardError
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*дай ёбу/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      yoba = File.basename(Dir['public/*'].sample); m.reply("https://your-domain.ga/#{yoba}")
    end
  end


  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*ищи (\p{Cyrillic}{4,})/i) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if n.match?(/хохл/i)
        hohols = m.channel.users.select do |u|
          begin
            host = u.host.match?(/kiwiirc/i) ? u.host.match(/\d+\.\d+\.\d+\.\d+/)[0] : u.host
            GeoIP.new('GeoLiteCity.dat').country(host).country_code2 == 'UA' and !$no_highlight_nicks.include?(u.nick)
          rescue StandardError
          end
        end.map { |u| u[0].nick }
        m.reply hohols.empty? ? 'Хохлы не обнаружены!'.ubernation_days : "Хохлы обнаружены: #{hohols.join(', ')}".ubernation_days
      else
        n = n.gsub(/ов$/, 'ÜÜÜ').gsub(/ей$/, 'ьÜÜÜ').gsub(/ев$/, 'йÜÜÜ').gsub(/их$/, 'ийÜÜÜ').gsub(/ек$/, 'каÜÜÜ').gsub(/ак$/, 'акаÜÜÜ').gsub(/ых$/, 'ыеÜÜÜ').gsub(/ÜÜÜ/, '')
        random_search = []
        m.channel.users.each do |u|
          if rand < 0.04
            if $no_highlight_nicks.include?(u[0].nick)
              random_search << u[0].nick.dup.insert(1, '‍')
            else
              random_search << u[0].nick
            end

          end
        end
        n = URI.encode(n)
        doc = Nokogiri.parse(open("https://ws3.morpher.ru/russian/declension?s=#{n}").read)
        puts "\nСсылка: https://ws3.morpher.ru/russian/declension?s=#{n}\n"
        puts doc.to_s
        sklonen = doc.search('И').map(&:text)
        if sklonen.empty?
          sklonen = doc.search('В').map(&:text)
        end
        ans1 = sklonen[0].capitalize.to_s + ' не обнаружены!'
        ans2 = sklonen[0].capitalize.to_s + " обнаружены: #{random_search.join(', ')}"
        m.reply random_search.empty? ? ("\00303" + ans1.ubernation_days + "\n") : ("\00303" + ans2.ubernation_days + "\n")
      end
    end
  end



  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*ищи бульбашей/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      bulbs = m.channel.users.select do |u|
        begin
          host = u.host.match(/\d+\.\d+\.\d+\.\d+/)[0]
          GeoIP.new('GeoLiteCity.dat').country(host).country_code2 == 'BY' and !$no_highlight_nicks.include?(u.nick)
        rescue StandardError
        end
      end.map { |u| u[0].nick }
      m.reply bulbs.empty? ? 'Бульбаши не обнаружены!'.ubernation_days : "Бульбаши обнаружены: #{bulbs.join(', ')}".ubernation_days
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*(прекрати|перестань|завязывай|кончай|заканчивай|заебала|хватит)\s*(?:меня|мне)?\s*(хайлайтить|подсвечивать|дергать|мешать|упоминать)/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if $no_highlight_nicks.include?(m.user.nick)
        m.action_reply "и так старается не хайлайтить #{m.user.nick.dup.insert(1, '‍')}".ubernation_days
      else
        $no_highlight_nicks.push(m.user.nick) unless $no_highlight_nicks.include?(m.user.nick)
        m.action_reply "больше не будет хайлайтить #{m.user.nick.dup.insert(1, '‍')}".ubernation_days
      end
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*(хайлайти|подсвечивай|дергай|мешай|упоминай)\s*(снова|опять|меня)/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if $no_highlight_nicks.include?(m.user.nick)
        $no_highlight_nicks.delete(m.user.nick)
        m.action_reply "опять хайлайтит #{m.user.nick}".ubernation_days
      else
        m.action_reply "и так хайлайтила #{m.user.nick}".ubernation_days
      end
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*ищи из (.+)/i) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      country = m.channel.users.select do |u|
        begin
          host = u.host.match(/\d+\.\d+\.\d+\.\d+/)[0]
          db = SypexGeo::Database.new('./SxGeoCity.dat')
          db.query(host)&.country&.[](:iso) == n and !$no_highlight_nicks.include?(u.nick)
        rescue StandardError
        end
      end.map { |u| u[0].nick }
      m.reply country.empty? ? 'Не найдены!'.ubernation_days : "#{n}.kapitalizirovat_russky найдены: #{country.join(', ')}".ubernation_days
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*ищи нерусей/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      norus = m.channel.users.select do |u|
        begin
          host = u.host.match(/\d+\.\d+\.\d+\.\d+/)[0]
          GeoIP.new('GeoLiteCity.dat').country(host).country_code2 != 'RU' and !$no_highlight_nicks.include?(u.nick)
        rescue StandardError
        end
      end.map { |u| u[0].nick }
      m.reply norus.empty? ? 'Нерусь не обнаружена!'.ubernation_days : "Лови нерусь: #{norus.join(', ')}".ubernation_days
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*накатим/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      [3, 2, 1].each { |e| m.reply "#{e}..."; sleep 2 }
      m.reply 'НАКАТИМ!'.ubernation_days
    end
  end

  on(:message, /(Слава Україні|Слава Украине)/i) do |m|
    m.reply 'Героям слава!' unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
  end

  on(:message, /!донгер/) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      @dongers ||= File.readlines 'dongers.txt'; m.reply @dongers.sample.strip
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка), а (.+)\?[^\s]*/i do |m, a1|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || a1.match?(/(^ ?| )или( | ?$)/) || a1.match?(/(^ ?| )ли( | ?$)/)
      @check = Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5
      if @check
        if @last_match[2] == @check
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "И #{a1} - тоже #{@last_match[0]}!" : "И #{a1} - однозначно #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        elsif @last_match[2] == 'ili'
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "Можно и #{a1}!" : "ЯÜÜÜ думаю, #{a1} тоже хорошо!").zamena_mestoimeniy.ubernation_days)
        else
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "A #{a1} - #{@last_match[0]}!" : "А вот #{a1} - #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        end
      else
        if @last_match[2] == @check
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "И #{a1} - не #{@last_match[0]}!" : "И #{a1} - совсем не #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        elsif @last_match[2] == 'ili'
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "А вот #{a1} - не стоит!" : "А #{a1} - не нужно!").zamena_mestoimeniy.ubernation_days)
        else
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "А #{a1} - не #{@last_match[0]}!" : "А #{a1} - совершенно не #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        end
      end
      @last_match[2] = @check
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка), а (.+) или (.+)\?[^\s]*/i do |m, a1, a2|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || a1.match?(/(^ ?| )ли( | ?$)/) || a2.match?(/(^ ?| )ли( | ?$)/)
      if Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5
        nash_variant = a1
      else
        nash_variant = a2
      end

      @check = Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5
      if @check
        if @last_match[2] == @check
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "#{nash_variant} - тоже #{@last_match[0]}!" : "#{nash_variant} - однозначно #{@last_match[0]}!").zamena_mestoimeniy.kapitalizirovat_russky.ubernation_days)
        elsif @last_match[2] == 'ili'
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "Можно и #{nash_variant}!" : "ЯÜÜÜ думаю, #{nash_variant} тоже хорошо!").zamena_mestoimeniy.ubernation_days)
        else
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "A #{nash_variant} - #{@last_match[0]}!" : "А вот #{nash_variant} - #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        end
      else
        if @last_match[2] == @check
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "И #{nash_variant} - не #{@last_match[0]}!" : "И #{nash_variant} - совсем не #{@last_match[0]}!").zamena_mestoimeniy.ubernation_days)
        elsif @last_match[2] == 'ili'
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "Ну #{nash_variant} - точно не стоит!" : "Вот #{nash_variant} - однозначно не нужно!").zamena_mestoimeniy.ubernation_days)
        else
          m.safe_reply((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "#{nash_variant} - не #{@last_match[0]}!" : "#{nash_variant} - совершенно не #{@last_match[0]}!").zamena_mestoimeniy.kapitalizirovat_russky.ubernation_days)
        end
      end
      @last_match[2] = @check
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка),.+(?:выбери|выбрать|посоветуй|дай совет).+:(.+(?:(,|или)).+)+(\?|\!|\.)[^\s]*/i do |m, a1|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      a1.gsub!(' или ', ',')
      our_answer_array = []
      if Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + a1).to_i(16).to_f).rand > 0.85
        our_source_array = a1.split(/,/).map(&:strip)
        our_answer_array.push(our_source_array.delete_at(Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + a1).to_i(16).to_f).rand(our_source_array.count)))
        our_answer_array.push(our_source_array.delete_at(Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + a1).to_i(16).to_f).rand(our_source_array.count)))
        answers = ['Конечно же', 'Мне кажется,', 'Я считаю,']
        answers2 = ['или', 'ну или']
        answers3 = ['!', '.', '...']
        final_answer = "#{answers.sample} " + (our_answer_array[0]).to_s.zamena_mestoimeniy + " #{answers2.sample} " + (our_answer_array[1]).to_s.zamena_mestoimeniy + (answers3.sample).to_s
        m.safe_replyfinal_answer.ubernation_days

      else
        our_source_array = a1.split(/,/).map(&:strip)
        our_answer_array.push(our_source_array.delete_at(Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + a1).to_i(16).to_f).rand(our_source_array.count)))
        answers = ['Конечно же', 'Мне кажется,', 'Я считаю,']
        answers2 = ['!', '.', '...']
        final_answer = "#{answers.sample} " + (our_answer_array[0]).to_s.zamena_mestoimeniy + (answers2.sample).to_s
        m.safe_replyfinal_answer.ubernation_days
      end
    end
  end






  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*(.+) ли (.+)\?[^\s]*/i do |m, a1, a2|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || a1.match?(/(^ ?| )а( | ?$)/) || a2.match?(/(^ ?| )или( | ?$)/)
      if a2[/^вы$/i]
        m.safe_reply('Кто "вы", блять? Я здесь одна, нахуй!').kapitalizirovat_russky.ubernation_days
        return
      end
      @check = Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5
      @last_match = [a1, a2, @check]
      final_answer = "#{@last_match[1]}#{@check ? ' ' : [' не ', ' ни разу не '].sample}#{@last_match[0]}".zamena_mestoimeniy.kapitalizirovat_russky
      m.safe_reply(final_answer.ubernation_days)
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*(.+) или (.+)\?[^\s]*/i do |m, a1, a2|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || a1.match?(/(^ ?| )а( | ?$)/) || a1.match?(/(^ ?| )ли( | ?$)/) || a2.match?(/(^ ?| )ли( | ?$)/)
      @last_match[2] = 'ili'
      answers = ['Конечно же', 'Мне кажется,', 'Я считаю,']
      ili_rand = Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand
      if ili_rand < 0.1
        final_answer = "#{answers.sample} " + (Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "ни #{a1}, ни тем более не #{a2}!" : "не #{a1} и не #{a2}!").zamena_mestoimeniy
        m.safe_reply(final_answer.ubernation_days)
      elsif ili_rand >= 0.1 && ili_rand < 0.9
        final_answer = "#{answers.sample} " + ((Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? a1 : a2)).to_s.zamena_mestoimeniy
        m.safe_replyfinal_answer.ubernation_days
      else
        final_answer = "#{answers.sample} " + (Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "#{a1} и #{a2}!" : "и #{a1} и #{a2}!").zamena_mestoimeniy.kapitalizirovat_russky
        m.safe_reply(final_answer.ubernation_days)
      end
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*(.+) ли (.+) или (.+)\?[^\s]*/i do |m, a1, a1main, a2|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || a1.match?(/(^ ?| )а( | ?$)/)
      @last_match[2] = 'ili'
      answers = ['Конечно же', 'Мне кажется,', 'Я считаю,']
      ili_rand = Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand
      if ili_rand < 0.333333
        final_answer = "#{answers.sample} " + a2.to_s.zamena_mestoimeniy
        m.safe_replyfinal_answer.ubernation_days
      else
        final_answer = "#{answers.sample} " + (Random.new(Digest::MD5.hexdigest(Time.now.strftime('%d/%m/%Y') + m.user.nick + m.message).to_i(16).to_f).rand > 0.5 ? "#{a1main} - #{a1}!" : "#{a1main} не #{a1}!").zamena_mestoimeniy
        m.safe_reply(final_answer.ubernation_days)
      end
    end
  end


  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*посоветуй кинцо/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      @movies ||= File.readlines('movies.txt')
      title, link = @movies.sample.split(',,,')
      link = "http://imdb.com#{link.strip}"
      if $no_highlight_nicks.include?(m.user.nick)

        m.reply "#{m.user.nick.dup.insert(1, '‍')}, #{title.ubernation_days} - #{link}"

      else
        m.reply "#{m.user.nick}, #{title.ubernation_days} - #{link}"
      end

    end
  end


  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*профилируй память/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

      MemoryProfiler.start
      m.reply 'Консолечка профилирует!'.ubernation_days
    end
  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s*сохрани отчёт/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      report = MemoryProfiler.stop
      report.pretty_print(to_file: "/konsolechka/memory-report-#{Time.now.strftime('%d.%m.%Y.%m.%d-%H-%M')}.log")
      m.reply 'Консолечка сохранила репорт!'.ubernation_days
    end
  end



  on :message, %r{((?:http|https)://\S+)}i do |m, n|
    break unless m.channel

    if n.match?(%r{.*2ch.*news/res/.*}i)
      @megumin_variants = ['Megumin, кончай бездельничать!', 'Megumin, съезжай от мамки!', 'Megumin, найди работу!', 'Megumin, стань самостоятельным!']

      m.safe_reply(@megumin_variants.sample).to_s.ubernation_days
    end
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || (n.include? 'chlor.ga') || n.match?(%r{.*2ch.*news/res/.*}i)


      url = Addressable::URI.parse(n)
      url.host = SimpleIDN.to_ascii(url.host)
      agent = Mechanize.new
      agent.keep_alive = false
      agent.max_history = 1
      agent.max_file_buffer = 65_535
      agent.redirection_limit = 3
      agent.idle_timeout = 1
      agent.ignore_bad_chunking = true
      agent.keep_alive = false
      agent.open_timeout = 3
      agent.read_timeout = 4

      agent.open_timeout = 4
      agent.read_timeout = 4
      agent.user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.3282.39 Safari/537.36 kons'
      begin
        @isfile = agent.head(url.to_s).instance_of?(Mechanize::File) || agent.head(url.to_s).instance_of?(Mechanize::Image)
      rescue StandardError
        @isfile = false
      end
      if @isfile
        resp = agent.head(url.to_s)
        ActionView::Base.new
        title = ''
        if resp.instance_of?(Mechanize::File)
          title << "Файл (#{ActionView::Base.new.number_to_human_size(resp.response['content-length']).gsub(/\bКБ\b/, 'КиБ').gsub(/\bМБ\b/, 'МиБ')})"
        else
          dims = FastImage.size(resp.uri.to_s)
          type = resp.response['content-type'].match(%r{/(\w+)})[1]
          # length = ActionView::Base.new.number_to_human_size(resp.response['content-length'])
          length = ActionView::Base.new.number_to_human_size(FastImage.new(resp.uri.to_s).content_length).gsub(/\bКБ\b/, 'КиБ').gsub(/\bМБ\b/, 'МиБ')
          title << "Изображение (#{length}, #{dims[0]}×#{dims[1]}, #{type})"
        end
        m.safe_reply title.gsub(/[^[:print:]]/i, ' ').gsub(/\r\n/, ' ').tr("\n", ' ').strip.ubernation_days
      else
        agent.get url.to_s
        title = agent.page.search('title')[0].text.strip.gsub(/ - YouTube/, '').gsub(/\s+/, ' ').gsub(/\s+([,\.!])/, '\1').gsub(%r{([,\.!])(?![\s\d]+)(?![$/])}, '\1').gsub(/(\d+),(\d+)/, '\1.\2').gsub(/(\d+)\*(\d+)/i, '\1×\2').gsub(/(\d+)Х(\d+)/i, '\1×\2').gsub(/(\d+)х(\d+)/i, '\1×\2').gsub(/(\d+)x(\d+)/i, '\1×\2').gsub(/"([\p{Cyrillic}|\s|0-9|×]*)"/m, '«\1»').gsub(/« /, '«').gsub(/ »/, '»')
        if agent.page.uri.to_s.match?(%r{youtube\.com/watch}) || agent.page.uri.to_s.match?(/youtu\.be/)

          if title.empty? || title == 'YouTube'
            title = agent.page.search('meta[name="title"]')[0][:content].strip.gsub(/ - YouTube/, '').gsub(/\s+/, ' ').gsub(/\s+([,\.!])/, '\1').gsub(%r{([,\.!])(?![\s\d]+)(?![$/])}, '\1').gsub(/(\d+),(\d+)/, '\1.\2').gsub(/(\d+)\*(\d+)/i, '\1×\2').gsub(/(\d+)Х(\d+)/i, '\1×\2').gsub(/(\d+)х(\d+)/i, '\1×\2').gsub(/(\d+)x(\d+)/i, '\1×\2').gsub(/"([\p{Cyrillic}|\s|0-9|×]*)"/m, '«\1»').gsub(/« /, '«').gsub(/ »/, '»')
          end
          view_count_tmp = agent.page.search('.watch-view-count').text.gsub(/ views/, '')
          if view_count_tmp.length > 0
            view_count = view_count_tmp.tr('^0-9', '').to_i
          end
          watcher_live_names = %w[зрителей зритель зрителя]
          watcher_names = %w[просмотров просмотр просмотра]

          unless (view_count.is_a? Integer)
            view_count_tmp = agent.page.search('script').text.scan(/videoViewCountRenderer":{"viewCount":{"simpleText":"([0-9\.,\ ]+) (?:views|Aufrufe)"}/im)
             if view_count_tmp.length > 0
               view_count = view_count_tmp[0][0].tr('^0-9', '').to_i
             end
          end

          unless (view_count.is_a? Integer)
            view_count_tmp = agent.page.search('script').text.scan(/videoViewCountRenderer\\":{\\"viewCount\\":{\\"simpleText\\":\\"([0-9\.,\ ]+) /im)
             if view_count_tmp.length > 0
               view_count = view_count_tmp[0][0].tr('^0-9', '').to_i
             end
          end

          if !(view_count.is_a? Integer)
            view_count_num_tmp = agent.page.search('script').text.scan(/viewCount\\":\{\\"runs\\":\[\{\\"text\\":\\"(?:Aktuell )?([0-9\.,\ ]+) (?:watching now|Zuschauer)\\"\}/im)

             if view_count_num_tmp.length > 0
               view_count_num = view_count_num_tmp[0][0].tr('^0-9', '').to_i
             end

             unless (view_count_num.is_a? Integer)
               view_count_num_tmp = agent.page.search('script').text.scan(/videoViewCountRenderer":{"viewCount":{"runs":\[{"text":"(?:[^\ 0-9]+ )?([0-9\.,\ ]+) /im)
                if view_count_num_tmp.length > 0
                  view_count_num = view_count_num_tmp[0][0].tr('^0-9', '').to_i
                end
             end

             w_index = view_count_num % 100

             if w_index >= 11 && w_index <= 14
               a_index = 0
             else
               if (w_index % 10) < 5
                 if (w_index % 10) > 2
                   a_index = 2
                 else
                   a_index = w_index % 10
                 end
               else
                 a_index = 0
               end

             end

             view_count_str =  number_with_delimiter(view_count_num, delimiter: ',')
             watcher_live_name = watcher_live_names[a_index]

             title = title.ubernation_days + ' ' + "(#{view_count_str} #{watcher_live_name})".ubernation_days

          else
            view_count_num = view_count


             w_index = view_count_num % 100

             if w_index >= 11 && w_index <= 14
               a_index = 0
             else
               if (w_index % 10) < 5
                 if (w_index % 10) > 2
                   a_index = 2
                 else
                   a_index = w_index % 10
                 end
               else
                 a_index = 0
               end

             end

             view_count_str = number_with_delimiter(view_count_num, delimiter: ',')

             watcher_name = watcher_names[a_index]

             title = title.ubernation_days + ' ' + "(#{view_count_str} #{watcher_name})".ubernation_days
          end

        end
        safe_title = title.gsub(/[^[:print:]]/i, ' ').gsub(/\r\n/, ' ').tr("\n", ' ').strip
        if safe_title.length > 400
          m.safe_reply safe_title.slice(0, 400)
        else
          m.safe_reply safe_title
        end
      end
    end
  end


  # on :message do |m|
  #  name = m.user.nick
  #  msg = m.message
  #  channel = m.channel&.name
  #
  #  u = User.first_or_create(name: name)
  #  mes = Message.create(text: msg, user: u, channel: channel)
  #  if mes.id.to_s.chars.uniq.length == 1
  #    m.channel.action "поздравила #{m.user.nick} с гетом (сообщение №#{mes.id})!".ubernation_days
  #  end
  # end

  # on :join do |m|
  #  name = m.user.nick
  #  host = m.user.host
  #  u = User.first_or_create(name: name)
  #  h = Host.create(host: host, user: u)
  # end

  on :notice, /VERSION/ do |mn|
    unless @ignored_users.include?(mn.user.host) || @ignored_nicks.include?(mn.user.nick) || @replied
      nick = mn.user.nick
      version = mn.params[1].match(/\u0001VERSION (.+)\u0001/)[1]
      if $no_highlight_nicks.include?(nick)
        Channel('#konsolechka').send "#{nick.dup.insert(1, '‍')} использует #{version}".gsub(/[^[:print:]]/i, '').ubernation_days
      else
        Channel('#konsolechka').send "#{nick} использует #{version}".gsub(/[^[:print:]]/i, '').ubernation_days
      end

      @replied = true
    end
  end

  on :message, /^!лгбт (.+)/ do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

      c = [5, 4, 8, 3, 2, 6].cycle
      result = n.ubernation_days.chars.map do |e|
        if e.match?(/^\s+$/)
          "\017#{e.center(3)}"
        else
          "\0031,#{c.next}" + e.center(3)
        end
      end

      m.reply result.join
    end
  end

  on :message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка), скажи (\S+) (.+)/ do |m, n, l|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      if n.match?(/\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]*\z/i)
        @tells ||= Hash.new { |h, k| h[k] = [] }
        if m.channel.users.map {|e| e[0].nick }.include?(n)
          if $no_highlight_nicks.include?(m.user.nick)

            m.reply("#{m.user.nick.dup.insert(1, '‍')}, в шары долбишься?".ubernation_days)

          else
            m.reply("#{m.user.nick}, в шары долбишься?".ubernation_days)
          end

        else
          if @tells[n].length >= 5
            if $no_highlight_nicks.include?(m.user.nick)


              m.reply("#{m.user.nick.dup.insert(1, '‍')}, лимит сообщений (5) достигнут.".ubernation_days)

            else
              m.reply("#{m.user.nick}, лимит сообщений (5) достигнут.".ubernation_days)
            end


          else
            @tells[n] << l
            m.channel.action 'скажет!'
            File.open('tells.txt', 'w') {|f| f.puts @tells.to_json }
          end
        end
      else
        if $no_highlight_nicks.include?(m.user.nick)

          m.reply("#{m.user.nick.dup.insert(1, '‍')} у тебя хуйня вместо ника.".ubernation_days)
        else
          m.reply("#{m.user.nick} у тебя хуйня вместо ника.".ubernation_days)
        end

      end
    end
  end

  on :join do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)
      @tells ||= Hash.new { |h, k| h[k] = [] }
      @tells[m.user.nick].each do |e|
        m.safe_reply "#{m.user.nick}, #{e}"
      end
      @tells.delete(m.user.nick)
    end
  end

  on(:message, /^\?([[:alnum:]]+)ша/i) {|m, n| @ysh ||= {}; (y = @ysh[n.to_s])&.send(:[], 0)&.send(:>, Time.now - 3600) && m.reply("#{n}ша этого часа -- #{y[1]}".ubernation_days) or (m.reply("И #{n}шей этого часа становится…".ubernation_days); sleep 3; @ysh[n] = [Time.now, (z = Channel('#s2ch').users.map {|u| u[0].nick }.sample)]; m.reply("#{z}! Поздравляем!".ubernation_days)) }


  on :join do |m|
    @logins ||= {}
    nick = m.user.nick
    if !@logins[nick] || Time.now - @logins[nick] > 300
      m.user.ctcp 'VERSION'
      @logins[nick] = Time.now
      @replied = false
    end
  end


  # ИГРА ПРО ПИДОРОВ

  # Инициализация на старте

  on :connect do
    @bots = ['AnimeChan', 'ChirnoBot', 'coinBot', 'Konsolechka', 'Maj_Petrenko', 'Qubick', 'Sopel', 'yalb', 'urp', 'AnimeChan_', 'coinBot_', 'Konsolechka_', 'Maj_Petrenko_', 'Qubick_', 'Sopel_', 'yalb_', 'urp_']

    # Загрузка состояний


    begin
      $pidors = YAML.load_file('/konsolechka/configstorage/pidors.yml')
    rescue Errno::ENOENT
      $pidors = {}
    end

    begin
      $last_messages_time = YAML.load_file('/konsolechka/configstorage/last_messages_time.yml')
    rescue Errno::ENOENT
      $last_messages_time = {}
    end

    begin
      $first_pidor = YAML.load_file('/konsolechka/configstorage/first_pidor.yml')
    rescue Errno::ENOENT
      $first_pidor = {}
    end

    begin
      $pidor_time = YAML.load_file('/konsolechka/configstorage/pidor_time.yml')
    rescue Errno::ENOENT
      $pidor_time = Time.now.to_i
    end

    begin
      $debug_mode = YAML.load_file('/konsolechka/configstorage/debug_mode.yml')
    rescue Errno::ENOENT
      $debug_mode = false
    end

    begin
      $game_started = YAML.load_file('/konsolechka/configstorage/game_started.yml')
    rescue Errno::ENOENT
      $game_started = false
    end

    begin
      $auto_pidor_triggered_last = YAML.load_file('/konsolechka/configstorage/auto_pidor_triggered_last.yml')
    rescue Errno::ENOENT
      $auto_pidor_triggered_last = false
    end

    begin
      $game_ending = YAML.load_file('/konsolechka/configstorage/game_ending.yml')
    rescue Errno::ENOENT
      $game_ending = false
    end

    begin
      $prev_winner = YAML.load_file('/konsolechka/configstorage/prev_winner.yml')
    rescue Errno::ENOENT
      $prev_winner = {}
    end

    begin
      $game_session_number = YAML.load_file('/konsolechka/configstorage/game_session_number.yml')
    rescue Errno::ENOENT
      $game_session_number = 0
    end

    begin
      $prev_winner = YAML.load_file('/konsolechka/configstorage/prev_winner.yml')
    rescue Errno::ENOENT
      $prev_winner = {}
    end

    begin
      $game_ending_started = YAML.load_file('/konsolechka/configstorage/game_ending_started.yml')
    rescue Errno::ENOENT
      $game_ending_started = 0
    end

    begin
      $no_highlight_nicks = YAML.load_file('/konsolechka/configstorage/no_highlight_nicks.yml')
    rescue Errno::ENOENT
      $no_highlight_nicks = []
    end


    begin
      $first_pidor_data = YAML.load_file('/konsolechka/configstorage/first_pidor_data.yml')
    rescue Errno::ENOENT
      $first_pidor_data = Cinch::User
    end


    Thread.new do
      sleep(10)

      # Восстановление войсов и статусов
      if $game_started || $game_ending

        Channel('#konsolechka').users.each do |u|
          next if @bots.include?(u[0].nick)
          if $pidors.select {|_k, v| v[:nick] == u[0].nick } == {}
            if $pidors.select {|_k, v| v[:host] == u[0].host } == {}
              if $last_messages_time[u[0].nick] == nil
                $last_messages_time[u[0].nick] = Time.now
              end
              $pidors[$pidors.count] = { :nick => u[0].nick, :host => u[0].host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[u[0].nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
            else


              if $pidors.select {|_k, v| v[:host] == u[0].host }.count > 1
                if $pidors.select {|_k, v| v[:host] == u[0].host }.select {|_kk, vv| vv[:pidor_status] == true }.count > 0
                  $pidors[$pidors.count] = { :nick => u[0].nick, :host => u[0].host, :pidor_status => true, :chance => 125, :last_message => $last_messages_time[u[0].nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
                else
                  $pidors[$pidors.count] = { :nick => u[0].nick, :host => u[0].host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[u[0].nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
                end
              else
                $pidors[$pidors.select {|_k, v| v[:host] == u[0].host }.values.last[:num]][:nick] = u[0].nick
              end
            end
          end

          if $pidors.select {|_k, v| v[:host] == u[0].host } == {}
            if $pidors.select {|_k, v| v[:nick] == u[0].nick } == {} || (u[0].nick != $pidors[$pidors.select {|_k, v| v[:nick] == u[0].nick }.values.last[:num]][:nick])
              if $last_messages_time[u[0].nick] == nil
                $last_messages_time[u[0].nick] = Time.now
              end
              $pidors[$pidors.count] = { :nick => u[0].nick, :host => u[0].host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[u[0].nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
            else
              $pidors[$pidors.select {|_k, v| v[:nick] == u[0].nick }.values.last[:num]][:host] = u[0].host
            end
          end
        end

        $pidors.each do |_ke, va|
          next if @bots.include?(va[:nick])
          if Channel('#konsolechka').has_user?(va[:nick]) && !$pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active]
            $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active] = true
          else
            if (!Channel('#konsolechka').has_user?(va[:nick]) && $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active])
              $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active] = false
            end
          end
          if $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:pidor_status]
            if Channel('#konsolechka').has_user?(va[:nick]) && !Channel('#konsolechka').voiced?(va[:nick])
              User('ChanServ').send("VOICE #konsolechka #{va[:nick]}")
            end
          else
            if Channel('#konsolechka').has_user?(va[:nick]) && Channel('#konsolechka').voiced?(va[:nick])
              User('ChanServ').send("DEVOICE #konsolechka #{va[:nick]}")
            end
          end
        end
        if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
          $game_ending = true
          $game_ending_started = Time.now
          $game_started = false
          if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days



          else
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days


          end
          $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now.strftime('%d.%m.%Y %H:%M'), :glavpidor => $first_pidor_data&.nick }

          Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
            unless @bots.include?(u)
              if (Channel('#konsolechka').voiced?(u))
                User('ChanServ').send("DEVOICE #konsolechka #{u}")
              end
            end
          end
          sleep 60
          $game_ending = false
        end


        if $game_ending

          Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
            unless @bots.include?(u)
              if (Channel('#konsolechka').voiced?(u))
                User('ChanServ').send("DEVOICE #konsolechka #{u}")
              end
            end
          end
          sleep 60
          $game_ending = false
        end
      else

        # Убирание войсов у людей

        Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
          unless @bots.include?(u)
              if (Channel('#konsolechka').voiced?(u))
                User('ChanServ').send("DEVOICE #konsolechka #{u}")
              end
          end
        end

        # Заполнение массива "старых" юзеров присутствующими на канале

        Channel('#konsolechka').users.each do |u|
          # Присваивание войсов ботам
          if @bots.include?(u[0].nick)
            User('ChanServ').send("VOICE #konsolechka #{u[0].nick}") if !(Channel('#konsolechka').voiced?(u[0].nick))
          end
        end
      end
    end
  end

  on(:message, /!правила/i) do |m|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick)
      if !$debug_mode
        m.reply 'Режим показа коэффициентов и вероятностей активирован'.ubernation_days
        $debug_mode = true
      else
        m.reply 'Режим показа коэффициентов и вероятностей отключен'.ubernation_days
        $debug_mode = false
      end
    end
  end

  on(:message, /!пидор/i) do |m|
    break if @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick)

    m.reply 'Игра про пидоров в данный момент сломана, приносим наши извинения!'.ubernation_days
    next
    if $game_ending
      m.reply "Игра про пидоров в данный момент завершается, пожалуйста подождите #{(60 - (Time.now - $game_ending_started)).ceil} сек.".ubernation_days

      if Channel('#konsolechka').voiced.count < 10
        sleep 15
        $game_ending = false
      end
    end
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick) || $game_ending
      if !$game_started
        $game_session_number = $game_session_number + 1
        $game_started = true
        $game_ending = false
        # обнуляем переменные
        $first_pidor.clear
        $pidors.clear
        $pidors = {}
        $first_pidor = {}
        $pidor_time = Time.now.to_i
        $auto_pidor_triggered_last = false

        loop do
          $first_pidor_data = m.channel.users.to_a.sample[0]
          if (!(@ignored_users.include?($first_pidor_data&.host) || @ignored_nicks.include?($first_pidor_data&.nick) || @bots.include?($first_pidor_data&.nick)))
            break
          end
        end

        if $last_messages_time[$first_pidor_data&.nick] == nil
          $last_messages_time[$first_pidor_data&.nick] = Time.now
        end

        $pidors[$pidors.count] = { :nick => $first_pidor_data&.nick, :host => $first_pidor_data&.host, :pidor_status => true, :chance => 10, :last_message => $last_messages_time[$first_pidor_data&.nick], :pidor_date => Time.now, :num => $pidors.count, :active => true, :last_attack_time => Time.now - 10_000 }




        m.channel.users.each do |u|
          unless @bots.include?(u[0].nick) || !($pidors.select {|_k, v| v[:nick] == u[0].nick } == {})
            if $last_messages_time[u[0].nick] == nil
              $last_messages_time[u[0].nick] = Time.now
            end
            $pidors[$pidors.count] = { :nick => u[0].nick, :host => u[0].host, :pidor_status => false, :chance => 10, :last_message => $last_messages_time[u[0].nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now - 10_000 }

          end
        end

        m.reply "Всё о победителях прошлых раундов - https://your-domain.ga/pidor/ !".ubernation_days if ($prev_winner)
        m.reply 'И новым главпидором становится...'.ubernation_days
        sleep 3

        User('ChanServ').send("VOICE #konsolechka #{$first_pidor_data&.nick}")

        if $no_highlight_nicks.include?($first_pidor_data&.nick)
          m.reply "#{$first_pidor_data&.nick.dup.insert(1, '‍')}! Поздравляем! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days
        else
          m.reply "#{$first_pidor_data&.nick}! Поздравляем! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days
        end
        $first_pidor = { :nick => $first_pidor_data&.nick, :date => Time.now.strftime('%d.%m.%Y %H:%M') }
        $pidor_time = Time.now.to_i

        player_list = []
        $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }

        sleep 3
        $pidors.each do |_ke, va|
          unless @bots.include?(va[:nick])
            if Channel('#konsolechka').has_user?(va[:nick])
              $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active] = true
              if $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:pidor_status]
                unless (Channel('#konsolechka').voiced?(va[:nick]))
                  User('ChanServ').send("VOICE #konsolechka #{va[:nick]}")
                end
              else
                if Channel('#konsolechka').voiced?(va[:nick])
                  User('ChanServ').send("DEVOICE #konsolechka #{va[:nick]}")
                end
              end
            else
              $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:active] = false
            end
          end
        end


      else
        $auto_pidor_triggered_last = false
        m.channel.users.each do |u|
          if @bots.include?(u[0].nick) && !m.channel.voiced?(u[0].nick)
            User('ChanServ').send("VOICE #konsolechka #{u[0].nick}")
          end
        end
        if $pidor_time + 3600 < Time.now.to_i

          if $debug_mode && $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:active]

            victory_chance = 0

            10_000.times do
              if (rand(1..($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count)) == $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count) && $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:active]
                victory_chance = victory_chance + 1
              end
            end
            victory_chance = (victory_chance / 100).ceil
            User(m.user.nick).send("Шанс снять статус пидора rand(1..#{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count})==#{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}: #{victory_chance}%".ubernation_days, true)
          end
          if (rand(1..($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count)) == $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count) && $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:active]

            User('ChanServ').send("DEVOICE #konsolechka #{m.user.nick}")
            $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:pidor_status] = false

            if $no_highlight_nicks.include?(m.user.nick)
              m.reply "Волею судеб, статус зашкваренного пидора был снят с #{m.user.nick.dup.insert(1, '‍')}. Поздравляем! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

            else
              m.reply "Волею судеб, статус зашкваренного пидора был снят с #{m.user.nick}. Поздравляем! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

            end



            player_list = []
            $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }


            $pidor_time = Time.now.to_i
          else
            @temp_new_pidors = []


            $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.each {|k, _n| k }.each do |_ke, va|
              (0..(va[:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == va[:nick] }.values.last[:num]][:last_message].to_i) / 900).ceil)).each do |_n|
                unless va[:nick] == m.user.nick
                  @temp_new_pidors << va[:nick]
                end
              end
            end


            @temp_new_pidor = @temp_new_pidors.to_a.sample
            m.reply 'И новым пидором становится...'.ubernation_days
            sleep 3

            User('ChanServ').send("VOICE #konsolechka #{@temp_new_pidor}")
            $pidors[$pidors.select {|_k, v| v[:nick][@temp_new_pidor] }.values.last[:num]][:pidor_status] = true

            if $no_highlight_nicks.include?(@temp_new_pidor)
              m.reply "#{@temp_new_pidor.dup.insert(1, '‍')}! Поздравляем! Хата зашкварена с #{$first_pidor[:date]}! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

            else
              m.reply "#{@temp_new_pidor}! Поздравляем! Хата зашкварена с #{$first_pidor[:date]}! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

            end

            $pidors.select {|_k, v| v[:host] == $pidors[$pidors.select {|_k, v| v[:nick] == @temp_new_pidor }.values.last[:num]][:host] }.values.each do |n|
              unless n[:nick] == @temp_new_pidor
                $pidors[n[:num]][:pidor_status] = true
                User('ChanServ').send("VOICE #konsolechka #{n[:nick]}")
              end
            end
            $pidor_time = Time.now.to_i

            if $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] > 10
              if $debug_mode
                old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]
              end
              $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - (($pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - 10) / rand(3..8)).ceil
              if $debug_mode
                User(m.user.nick).send("Ваш коэффициент понижен: #{old_chance}->#{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
              end


            end
            player_list = []
            $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
          end

        else
          m.reply "Хата зашкварена с #{$first_pidor[:date]}! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}. До возможности применить команду осталось #{distance_of_time_in_words(3600 - (Time.now.to_i - $pidor_time))} https://your-domain.ga/pidor/ - статистика".ubernation_days
        end

        if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
          $game_ending = true
          $game_ending_started = Time.now
          $game_started = false

          if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days



          else
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days


          end



          $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now.strftime('%d.%m.%Y %H:%M'), :glavpidor => $first_pidor_data&.nick }

          Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
            unless @bots.include?(u)
              if (Channel('#konsolechka').voiced?(u))
                User('ChanServ').send("DEVOICE #konsolechka #{u}")
              end
            end
          end
          sleep 60
          $game_ending = false
        end
      end
    end
  end

  on :join do |m|
    User('ChanServ').send("VOICE #konsolechka #{m.user.nick}") if @bots.include?(m.user.nick)
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick) || !$game_started || $game_ending

      if $pidors.select {|_k, v| v[:nick] == m.user.nick } == {}
        if $pidors.select {|_k, v| v[:host] == m.user.host } == {}
          if $last_messages_time[m.user.nick] == nil
            $last_messages_time[m.user.nick] = Time.now
          end
          $pidors[$pidors.count] = { :nick => m.user.nick, :host => m.user.host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[m.user.nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }

          player_list = []
          $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
        else
          if $pidors.select {|_k, v| v[:host] == m.user.host }.count > 1
            if $pidors.select {|_k, v| v[:host] == m.user.host }.select {|_kk, vv| vv[:pidor_status] == true }.count > 0
              $pidors[$pidors.count] = { :nick => m.user.nick, :host => m.user.host, :pidor_status => true, :chance => 125, :last_message => $last_messages_time[m.user.nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
            else
              $pidors[$pidors.count] = { :nick => m.user.nick, :host => m.user.host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[m.user.nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
            end
          else
            $pidors[$pidors.select {|_k, v| v[:host] == m.user.host }.values.last[:num]][:nick] = m.user.nick
          end
        end
      end

      if $pidors.select {|_k, v| v[:host] == m.user.host } == {}
        if $pidors.select {|_k, v| v[:nick] == m.user.nick } == {}
          if $last_messages_time[m.user.nick] == nil
            $last_messages_time[m.user.nick] = Time.now
          end
          $pidors[$pidors.count] = { :nick => m.user.nick, :host => m.user.host, :pidor_status => false, :chance => 25, :last_message => $last_messages_time[m.user.nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }

          player_list = []
          $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
        else
          $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:host] = m.user.host
        end
      end

      $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:active] = true


      player_list = []
      $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }

      if $pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:pidor_status]
        User('ChanServ').send("VOICE #konsolechka #{m.user.nick}") if !(m.channel.voiced?(m.user.nick))
      end

    end
  end

  on :catchall do |m|
    if m.command == 'NICK'
      unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick) || !$game_started || $game_ending
        if $last_messages_time[m.user.nick] == nil
          $last_messages_time[m.user.nick] = Time.now
        end
        old_nick = m.raw.scan(/^:([^!]{2,16}).*/)[0][0]
        if !($pidors.select {|_k, v| v[:host] == m.user.host } == {})
          if $pidors.select {|_k, v| v[:host] == m.user.host }.count > 1
            if $pidors.select {|_k, v| v[:host] == m.user.host }.select {|_kk, vv| vv[:pidor_status] == true }.count > 0
              $pidors[$pidors.select {|_k, v| v[:nick] == old_nick }.values.last[:num]][:nick] = m.user.nick
            else
              $pidors[$pidors.select {|_k, v| v[:nick] == old_nick }.values.last[:num]][:nick] = m.user.nick
            end

          else
            $pidors[$pidors.select {|_k, v| v[:host] == m.user.host }.values.last[:num]][:nick] = m.user.nick
            player_list = []
            $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
          end
        else
          if !($pidors.select {|_k, v| v[:nick] == old_nick } == {})
            $pidors[$pidors.select {|_k, v| v[:nick] == old_nick }.values.last[:num]][:host] = m.user.host
            $pidors[$pidors.select {|_k, v| v[:nick] == old_nick }.values.last[:num]][:nick] = m.user.nick
            player_list = []
            $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
          end
        end



      end
    end

    if m.command == 'PART' || m.command == 'QUIT'
      quitter_nick = m.raw.scan(/^:([^!]{2,16}).*/)[0][0]
      quitter_host = m.raw.scan(/^:[^!]{2,16}![^\ ]*@([^\ ]+).*/)[0][0]
      unless @ignored_users.include?(quitter_host) || @ignored_nicks.include?(quitter_nick) || @bots.include?(quitter_nick) || !$game_started || $game_ending
        if !($pidors.select {|_k, v| v[:host] == quitter_host } == {})
          if $pidors.select {|_k, v| v[:host] == quitter_host }.count > 1
          else
            $pidors[$pidors.select {|_k, v| v[:host] == quitter_host }.values.last[:num]][:active] = false
          end
        end
        if !($pidors.select {|_k, v| v[:nick] == quitter_nick } == {})
          $pidors[$pidors.select {|_k, v| v[:nick] == quitter_nick }.values.last[:num]][:active] = false
        end
        if !($pidors.select {|_k, v| v[:nick] == m.user.nick } == {})
          $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:active] = false
        end

        player_list = []
        $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }

        if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
          $game_ending = true
          $game_ending_started = Time.now
          $game_started = false
          if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days



          else
            m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days


          end
          $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now.strftime('%d.%m.%Y %H:%M'), :glavpidor => $first_pidor_data&.nick }

          Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
            unless @bots.include?(u)
              if (Channel('#konsolechka').voiced?(u))
                User('ChanServ').send("DEVOICE #konsolechka #{u}")
              end
            end
          end
          sleep 60
          $game_ending = false
        end

      end
    end
  end

  on :message do |m|
    name = m.user.nick
    msg = m.message


    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick) || !$game_started || msg.match?(/^(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s* зашкварь (.+)/i) || $game_ending

      if !($pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:pidor_status])
        if $pidors.select {|_kk, vv| vv[:pidor_status] }.select {|_kk, vv| vv[:active] }.map {|_kkk, vvv| vvv[:nick] }.any? { |s| msg.match?(/^.*\b#{s}\b.*$/i) }
          if $debug_mode
            old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]
          end
          $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] += rand(2..5)
          if $debug_mode
            User(m.user.nick).send("Коэффициент #{m.user.nick} увеличился на #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - old_chance} и стал равен #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
          end
        end
      end

      if msg.match?(/^.*(аниме(шники?)?|трапы?|habrahabr|хабра|альфабанк|альфа-банк|\b\)\)\b|\bgnome\b|\bгном\b|крыса|xfce|consolekit|polkit|systemd|системд|Леннарт|Поттеринг|Lennart|Poettering).*/i) && !($pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:pidor_status])

        if $debug_mode
          old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]
        end
        $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] += rand(1..4)
        if $debug_mode
          User(m.user.nick).send("Коэффициент #{m.user.nick} увеличился на #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - old_chance} и стал равен #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
        end
      end

      $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message] = Time.now
      $last_messages_time[m.user.nick] = Time.now


      if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
        $game_ending = true
        $game_ending_started = Time.now
        $game_started = false
        if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
          m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days



        else
          m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days


        end
        $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now.strftime('%d.%m.%Y %H:%M'), :glavpidor => $first_pidor_data&.nick }

        Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
          unless @bots.include?(u)
            if (Channel('#konsolechka').voiced?(u))
              User('ChanServ').send("DEVOICE #konsolechka #{u}")
            end
          end
        end
        sleep 60
        $game_ending = false
      end
    end

  end

  on(:message, /(?:Konsolech|Консол)(?:ь|еч|)(?:ka|ка)(?:,|\s+)\s* зашкварь (.+)/i) do |m, n|
    unless @ignored_users.include?(m.user.host) || @ignored_nicks.include?(m.user.nick) || @bots.include?(m.user.nick)
      m.reply 'Игра про пидоров в данный момент сломана, приносим наши извинения!'.ubernation_days
      next

      if !$game_started
        m.reply 'Игра про пидоров в данный момент неактивна, запустите её командой'.ubernation_days(+' !пидор')
      else
        if $game_ending
          m.reply "Игра про пидоров в данный момент завершается, пожалуйста подождите #{(60 - (Time.now - $game_ending_started)).ceil} сек.".ubernation_days
        else
          if $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:pidor_status]
            m.reply "Да ты сам зашкварен, чмо! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days
          else

            if !Channel('#konsolechka').has_user?(n.strip)
              m.reply "404: юзер #{n} не найден)".ubernation_days
            else
              user = User(n.strip)
              if !((Time.now - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_attack_time]) > 5)
                m.reply "До возможности применить команду осталось #{distance_of_time_in_words(5 - (Time.now - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_attack_time]))}".ubernation_days
              else
                $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_attack_time] = Time.now
                if user.nick == m.user.nick
                  if $no_highlight_nicks.include?(m.user.nick)

                    m.reply "#{m.user.nick.dup.insert(1, '‍')} со смаком пожрал своей ложкой из унитаза, запасшись силами!".ubernation_days


                  else
                    m.reply "#{m.user.nick} со смаком пожрал своей ложкой из унитаза, запасшись силами!".ubernation_days


                  end


                  if $debug_mode
                    old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]
                  end

                  $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] += rand(-3..6)

                  player_list = []
                  $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }

                  if $debug_mode
                    User(m.user.nick).send("Коэффициент #{m.user.nick} изменился на #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - old_chance} и стал равен #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
                  end


                else
                  if $pidors.select {|_k, v| v[:nick] == user.nick } == {}
                    $pidors[$pidors.count] = { :nick => user.nick, :host => user.host, :pidor_status => false, :chance => 10_000, :last_message => $last_messages_time[user.nick], :num => $pidors.count, :active => true, :last_attack_time => Time.now }
                  end
                  if $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:pidor_status]

                    if $no_highlight_nicks.include?(user.nick)


                      m.reply "#{user.nick.dup.insert(1, '‍')} уже зашкварен! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days


                    else
                      m.reply "#{user.nick} уже зашкварен! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days


                    end


                  else
                    if @bots.include?(user.nick)
                    else

                      our_rand = rand(0..($pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil + $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil))

                      if $debug_mode
                        User(m.user.nick).send("Коэффициенты #{m.user.nick}: #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]} (+#{((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil}), #{user.nick}: #{$pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance]} (+#{((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil})".ubernation_days, true)

                        User(m.user.nick).send("Формула победы нападающего: (rand(0..(#{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}+#{((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil}+#{$pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance]}+#{((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil})<=(#{$pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance]}+#{((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil})".ubernation_days, true)

                        victory_chance = 0

                        10_000.times do
                          if rand(0..($pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil + $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil)) <= ($pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil)
                            victory_chance = victory_chance + 1
                          end
                        end
                        victory_chance = (victory_chance / 100).ceil

                        User(m.user.nick).send("Результат: (#{our_rand}<#{($pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil)}) = #{(our_rand < $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil).to_s}. Шанс победы: #{victory_chance}%.".ubernation_days, true)

                      end

                      if our_rand <= ($pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:last_message].to_i) / 900).ceil)

                        $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:pidor_status] = true
                        $pidors.select {|_k, v| v[:host] == $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:host] }.values.each {|n| $pidors[n[:num]][:pidor_status] = true }
                        result_pidor_nick = user.nick

                        if $no_highlight_nicks.include?(user.nick) || $no_highlight_nicks.include?(m.user.nick)


                          m.reply "#{m.user.nick.dup.insert(1, '‍')} успешно зашкварил #{user.nick.dup.insert(1, '‍')}! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

                        else

                          m.reply "#{m.user.nick} успешно зашкварил #{user.nick}! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

                        end




                        result_pidor_nick = user.nick
                        User('ChanServ').send("VOICE #konsolechka #{user.nick}")
                        $pidors.select {|_k, v| v[:host] == $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:host] }.values.each do |n|
                          unless n[:nick] == result_pidor_nick
                            $pidors[n[:num]][:pidor_status] = true
                            User('ChanServ').send("VOICE #konsolechka #{n[:nick]}")
                          end
                        end
                        if $debug_mode
                          old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]
                        end
                        $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] += rand(-2..1)

                        if $debug_mode
                          User(m.user.nick).send("Коэффициент #{m.user.nick} изменился на #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance] - old_chance} и стал равен #{$pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
                        end

                      else
                        $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:pidor_status] = true
                        result_pidor_nick = m.user.nick
                        if $no_highlight_nicks.include?(user.nick) || $no_highlight_nicks.include?(m.user.nick)


                          m.reply "#{m.user.nick.dup.insert(1, '‍')} не сумел зашкварить #{user.nick.dup.insert(1, '‍')} и сам стал пидором! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

                        else

                          m.reply "#{m.user.nick} не сумел зашкварить #{user.nick} и сам стал пидором! Незашкваренных в хате осталось: #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count}".ubernation_days

                        end

                        User('ChanServ').send("VOICE #konsolechka #{m.user.nick}")

                        $pidors.select {|_k, v| v[:host] == $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:host] }.values.each do |n|
                          unless n[:nick] == result_pidor_nick
                            $pidors[n[:num]][:pidor_status] = true
                            User('ChanServ').send("VOICE #konsolechka #{n[:nick]}")
                          end
                        end

                        if $debug_mode
                          old_chance = $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance]
                        end
                        $pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] += rand(-2..0)

                        if $debug_mode
                          User(m.user.nick).send("Коэффициент #{user.nick} изменился на #{$pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance] - old_chance} и стал равен #{$pidors[$pidors.select {|_k, v| v[:nick] == user.nick }.values.last[:num]][:chance]}".ubernation_days, true)
                        end

                      end
                      player_list = []
                      $pidors.map {|_kkk, vvv| vvv[:nick] }.each {|n| player_list << { n => { :chance => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:chance] + ((Time.now.to_i - $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:last_message].to_i) / 900).ceil, :is_pidor => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:pidor_status], :is_online => $pidors[$pidors.select {|_k, v| v[:nick] == n }.values.last[:num]][:active] } } }
                    end
                    if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
                      $game_ending = true
                      $game_ending_started = Time.now
                      $game_started = false
                                 if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count == 1
                        if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
           
           
                          m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days
           
                        else
           
                          m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days
           
                        end
                                   $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now, :glavpidor => $first_pidor_data&.nick }
                      else
                                   m.reply 'И у нас нет победителя игры! На хате зашкварены все присутствующие! Поздравить некого!'.ubernation_days
           
                                   $prev_winner = { :nick => 'Konsolechka', :date => Time.now, :glavpidor => $first_pidor_data&.nick }
                                 end


                      Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
                        unless @bots.include?(u)
                          if (Channel('#konsolechka').voiced?(u))
                            User('ChanServ').send("DEVOICE #konsolechka #{u}")
                          end
                        end
                      end
                      sleep 60
                      $game_ending = false
                    end
                  end
                end
              end

            end


          end
          if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count <= 1 && !$game_ending && $game_started
            $game_ending = true
            $game_ending_started = Time.now
            $game_started = false
            if $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.count == 1
              if $no_highlight_nicks.include?($pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick])
                m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick].dup.insert(1, '‍')}! Поздравляем!".ubernation_days



              else
                m.reply "И у нас есть победитель игры! На хате не зашкварен только #{$pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick]}! Поздравляем!".ubernation_days


              end
              $prev_winner = { :nick => $pidors.select {|_k, v| !v[:pidor_status] }.select {|_kk, vv| vv[:active] }.values.last[:nick], :date => Time.now.strftime('%d.%m.%Y %H:%M'), :glavpidor => $first_pidor_data&.nick }
            else
              m.reply 'И у нас нет победителя игры! На хате зашкварены все присутствующие! Поздравить некого!'.ubernation_days

              $prev_winner = { :nick => 'Konsolechka', :date => Time.now, :glavpidor => $first_pidor_data&.nick }
            end
            #  $gamestats[:games][$game_session_number][:stats][:finished]=Time.now
            #  $gamestats[:games][$game_session_number][:stats][:winner]=$pidors.select{|k,v|!v[:pidor_status]}.select{|kk,vv|vv[:active]}.values.last[:nick]



            Channel('#konsolechka').voiced.map {|e| e.nick }.each do |u|
              unless @bots.include?(u)
                if (Channel('#konsolechka').voiced?(u))
                  User('ChanServ').send("DEVOICE #konsolechka #{u}")
                end
              end
            end
            sleep 60
            $game_ending = false
          end

        end


      end

      $pidors[$pidors.select {|_k, v| v[:nick] == m.user.nick }.values.last[:num]][:last_message] = Time.now
      $last_messages_time[m.user.nick] = Time.now
    end
  end
end


begin
  k.start
rescue SystemExit => e
  last_send = Cinch::Target.new('#konsolechka', k)

  File.open('/konsolechka/configstorage/pidors.yml', 'w') { |file| file.write(YAML.dump($pidors)) }
  File.open('/konsolechka/configstorage/last_messages_time.yml', 'w') { |file| file.write(YAML.dump($last_messages_time)) }
  File.open('/konsolechka/configstorage/first_pidor.yml', 'w') { |file| file.write(YAML.dump($first_pidor)) }
  File.open('/konsolechka/configstorage/pidor_time.yml', 'w') { |file| file.write(YAML.dump($pidor_time)) }
  File.open('/konsolechka/configstorage/game_started.yml', 'w') { |file| file.write(YAML.dump($game_started)) }
  File.open('/konsolechka/configstorage/debug_mode.yml', 'w') { |file| file.write(YAML.dump($debug_mode)) }
  File.open('/konsolechka/configstorage/auto_pidor_triggered_last.yml', 'w') { |file| file.write(YAML.dump($auto_pidor_triggered_last)) }
  File.open('/konsolechka/configstorage/game_ending.yml', 'w') { |file| file.write(YAML.dump($game_ending)) }
  File.open('/konsolechka/configstorage/game_session_number.yml', 'w') { |file| file.write(YAML.dump($game_session_number)) }
  File.open('/konsolechka/configstorage/prev_winner.yml', 'w') { |file| file.write(YAML.dump($prev_winner)) }
  File.open('/konsolechka/configstorage/game_ending_started.yml', 'w') { |file| file.write(YAML.dump($game_ending_started)) }
  File.open('/konsolechka/configstorage/no_highlight_nicks.yml', 'w') { |file| file.write(YAML.dump($no_highlight_nicks)) }
  File.open('/konsolechka/configstorage/first_pidor_data.yml', 'w') { |file| file.write(YAML.dump($first_pidor_data)) }

  sleep 1
  exit 130
end
