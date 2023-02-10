#!/usr/bin/ruby
require_relative '../../../../lib/objects/local_string_encoder.rb'
require 'sqlite3'
require 'date'
require 'fileutils' 

class FirefoxPlacesGenerator < StringEncoder
  attr_accessor :search_category
  attr_accessor :url_count
  attr_accessor :db
  attr_accessor :iterations
  # TODO: Assign variable on where History will go

  def initialize
    super
    self.module_name = 'Chromium History Generator'
    self.search_category = ''
    self.url_count = ''
    self.iterations = 1
    File.delete("History") if File.exist?("History")
    FileUtils.cp("#{INTERESTS_DIR}/History", "./History")
    self.db = SQLite3::Database.open "History"
  end

  def process_options(opt, arg)
    super
    if opt == '--SEARCH_CATEGORY'
      self.search_category << arg
    end
    if opt == '--URL_COUNT'
      self.url_count << arg
    end
  end
  
  def get_options_array
    super + [['--SEARCH_CATEGORY', '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--URL_COUNT', '-u', GetoptLong::OPTIONAL_ARGUMENT]
  ]
  end

  def get_webkit_timestamp
    since_epoch = '11644473600000'.to_i
    final_epoch = (((Time.now.to_f * 1000) + since_epoch).to_i).to_s + '000'
    return final_epoch
  end
    
  def get_search_term
    search_category = self.search_category
    # Read line from search_list file specified
    line = File.readlines("#{INTERESTS_DIR}/#{self.search_category.chomp}/search_phrases/#{self.search_category.chomp}").sample.chomp
    # replace spaces with pluses
    sanitised_search = line.downcase.gsub(' ', '+')
  end

  def create_google_search
    google_base = "https://www.google.com/search?q="
    search = get_search_term()
    result = ("#{google_base}#{search}")
    return result, search
    # self.outputs << "#{google_base}#{search}"
  end

  def create_places(db)
    # Convert epoch time to WebKit time - thanks Chromium!
    since_epoch = '11644473600000'.to_i
    final_epoch = (((Time.now.to_f * 1000) + since_epoch).to_i).to_s + '000'
    # db.execute("INSERT INTO 'urls' (url,	title, visit_count, typed_count, last_visit_time, hidden) VALUES ('#{create_google_search}', 'tolly765', '1', '0', '#{final_epoch}', '0');")
    # db.execute("INSERT INTO 'visits' (url, visit_time, from_visit, transition, segment_id, visit_duration, incremented_omnibox_typed_score, opener_visit, originator_cache_guid, originator_visit_id, originator_from_visit, originator_opener_visit, is_known_to_sync) VALUES ('1', '#{final_epoch}', '0', '838860805', '0', '0', '0', '0', '', '0', '0', '0', '0');")
  end
    
  def encode_all
    create_places(self.db)
    webkit_time = get_webkit_timestamp()
    iterations = self.url_count.to_i
    currentiter = 1
    while currentiter <= iterations
      puts currentiter
      search_url, search_term = create_google_search()
      search_term = search_term.downcase.gsub('+', ' ')
      db.execute("INSERT INTO 'urls' (url, 	title, visit_count, typed_count, last_visit_time, hidden) VALUES ('#{search_url}', '#{search_term}', '1', '0', '#{webkit_time}', '0');")
      db.execute("INSERT INTO 'visits' (url, visit_time, from_visit, transition, segment_id, visit_duration, incremented_omnibox_typed_score, opener_visit, originator_cache_guid, originator_visit_id, originator_from_visit, originator_opener_visit, is_known_to_sync) VALUES ('#{currentiter}', '#{webkit_time}', '0', '838860805', '0', '0', '0', '0', '', '0', '0', '0', '0');")
      currentiter += 1
    end
    db.execute("select * from urls") do |row|
      self.outputs << row
    end
  end

  # def encode_all
  #   iterations = self.iterations.to_i
  #   currentiter = 1
  #   while currentiter <= iterations
  #     google_base = "https://www.google.com/search?q="
  #     search = craft_search
  #     self.outputs << "#{google_base}#{search}"
  #     currentiter += 1
  #   end
  # end

  def encoding_print_string
    'Search Category: ' + self.search_category.to_s + ' | URL Count: ' + self.url_count
  end
  
  # def generate
  #   # read all the lines, and select one at random
  #   line = File.readlines("#{LINELISTS_DIR}/#{self.linelist.sample.chomp}").sample.chomp
  #   # strip out everything except alphanumeric and basic punctuation (no ' or ")
  #   self.outputs << line.gsub(/[^\w !.,]/, '')
  # end
end

FirefoxPlacesGenerator.new.run