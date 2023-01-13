#!/usr/bin/ruby
require_relative '../../../../lib/objects/local_string_encoder.rb'
require 'faker'

class GoogleSearchGenerator < StringEncoder
  attr_accessor :search_term

  def initialize
    super
    self.module_name = 'Google Search Encoder'
    self.search_term = ''
  end

  
  def process_options(opt, arg)
    super
    if opt == '--SEARCH_TERM'
      self.search_term << arg
    end
  end
  
  def get_options_array
    super + [['--SEARCH_TERM', GetoptLong::REQUIRED_ARGUMENT]]
  end
  # Creates a domain from the business_name
  def craft_search
    search_term = self.search_term
    # replace spaces
    sanitised_search = search_term.downcase.gsub(' ', '+')
    # strip punctuation and return
    # domain.gsub(/[^0-9a-z\s_-]/i, '')
  end
  
  def encode_all
    google_base = "https://www.google.com/search?q="
    search = craft_search
    self.outputs << "#{google_base}#{search}"
  end

  def encoding_print_string
    'Search Term: ' + self.search_term.to_s
  end
  
  # def generate
  #   # read all the lines, and select one at random
  #   line = File.readlines("#{LINELISTS_DIR}/#{self.linelist.sample.chomp}").sample.chomp
  #   # strip out everything except alphanumeric and basic punctuation (no ' or ")
  #   self.outputs << line.gsub(/[^\w !.,]/, '')
  # end
end

GoogleSearchGenerator.new.run