#!/usr/bin/ruby
require_relative '../../../../../lib/objects/local_hash_encoder.rb'
require 'openssl'

class SHA256Encoder < HashEncoder
  def initialize
    super
    self.module_name = 'SHA256 Encoder'
  end

  def hash_function(string)
    OpenSSL::Digest::SHA256.new.hexdigest(string)
  end
end

SHA256Encoder.new.run
