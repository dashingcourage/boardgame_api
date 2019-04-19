require 'nokogiri'
require 'open-uri'

GameArchive.destroy_all if Rails.env.development?
GameItem.destroy_all if Rails.env.development?

# GAMES DATABASE

ranked_titles = []

def get_titles(pages_count)
  game_rank_counter = 1
  pages_count = pages_count.to_a

  pages_count.each_with_index do |_page, index|

    url = "https://boardgamegeek.com/browse/boardgame/page/#{_page}"

    (1..100).each_with_index do |_item, index|

      # SCRAPE WEBSITE

      html_data = open(url).read
      html_doc = Nokogiri::HTML(html_data)
      game = {}

      name_array = []
      name_array << html_doc.search("#results_objectname#{_item} > a").inner_text

      game[:user_id] = 1
      game[:game_name] = name_array[0]
      game[:game_rank] = game_rank_counter
      game_rank_counter += 1
      #
      bgg_code = html_doc.search("#results_objectname#{_item} > a")[0]['href'].scan(/game.([0-9]*)/)
      bgg_id = bgg_code[0][0].to_i
      puts "Getting #{game[:game_name]} with id: #{bgg_id}"
      puts "~"

      # PARSE API

      api_url = "https://www.boardgamegeek.com/xmlapi2/thing?id=#{bgg_id}"
      xml_data = open(api_url).read
      xml_doc = Nokogiri::HTML(xml_data)

      playingtime_array = []
      xml_doc.search('playingtime').each do |ele|
        playingtime_array << ele.values.split(',')[0].last
      end

      game[:playing_time] = playingtime_array[0]

      boardgamecategory_array = []
      xml_doc.search('[type="boardgamecategory"]').each do |ele|
        boardgamecategory_array << ele.values[2]
      end

      game[:category] = boardgamecategory_array.first

      boardgamemechanic_array = []
      xml_doc.search('[type="boardgamemechanic"]').each do |ele|
        boardgamemechanic_array << ele.values[2]
      end

      game[:mechanic] = boardgamemechanic_array.first

      boardgamedesigner_array = []
      xml_doc.search('[type="boardgamedesigner"]').each do |ele|
        boardgamedesigner_array << ele.values[2]
      end

      game[:designer] = boardgamedesigner_array.first

      xml_doc.search('image').each do |ele|
        game[:image_url] = ele.text
      end

      thumb_image = xml_doc.search('thumbnail').each do |ele|
        game[:thumb_url] = ele.text
      end

      unless game[:game_name].nil?
        p game
        GameArchive.create!(game)
      end

      sleep(5)
      puts "====================================================================="
      puts ""
    end
  end
end

ranked_titles << get_titles(1..3)

puts "Finished seeding database..."
puts ""
