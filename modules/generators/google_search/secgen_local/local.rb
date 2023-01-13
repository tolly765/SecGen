#!/usr/bin/ruby
require_relative '../../../../lib/objects/local_string_encoder.rb'
require 'faker'

class GoogleSearchGenerator < StringEncoder
  attr_accessor :search_category
  attr_accessor :iterations

  def initialize
    super
    self.module_name = 'Google Search Encoder'
    self.search_category = ''
    self.iterations = ''
  end

  
  def process_options(opt, arg)
    super
    if opt == '--SEARCH_CATEGORY'
      self.search_category << arg
    end
    if opt == '--ITERATIONS'
      self.iterations << arg
    end
  end
  
  def get_options_array
    super + [['--SEARCH_CATEGORY', '-c', GetoptLong::REQUIRED_ARGUMENT],
    ['--ITERATIONS', '-i', GetoptLong::OPTIONAL_ARGUMENT]
  ]
  end
  # Creates a domain from the business_name
  def craft_search
    search_category = self.search_category
    # Read line from search_list file specified
    line = File.readlines("#{WORDLISTS_DIR}/search_lists/#{self.search_category.chomp}").sample.chomp

    # replace spaces with pluses
    sanitised_search = line.downcase.gsub(' ', '+')
    # strip punctuation and return
    # domain.gsub(/[^0-9a-z\s_-]/i, '')
  end
  
  def encode_all
    iterations = self.iterations.to_i
    currentiter = 1
    while currentiter <= iterations
      google_base = "https://www.google.com/search?q="
      search = craft_search
      self.outputs << "#{google_base}#{search}"
      currentiter += 1
    end
  end

  def encoding_print_string
    'Search Term: ' + self.search_category.to_s + ' | Iterations: ' + self.iterations
  end
  
  # def generate
  #   # read all the lines, and select one at random
  #   line = File.readlines("#{LINELISTS_DIR}/#{self.linelist.sample.chomp}").sample.chomp
  #   # strip out everything except alphanumeric and basic punctuation (no ' or ")
  #   self.outputs << line.gsub(/[^\w !.,]/, '')
  # end
end

GoogleSearchGenerator.new.run