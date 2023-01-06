#!/usr/bin/ruby
require_relative '../../../../../lib/objects/local_hash_encoder.rb'
require 'openssl'

class SHA1Encoder < HashEncoder
  def initialize
    super
    self.module_name = 'SHA1 Encoder'
  end

  def hash_function(string)
    OpenSSL::Digest::SHA1.new.hexdigest(string)
  end
end

SHA1Encoder.new.run
