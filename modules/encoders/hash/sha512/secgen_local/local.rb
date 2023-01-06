#!/usr/bin/ruby
require_relative '../../../../../lib/objects/local_hash_encoder.rb'
require 'openssl'

class SHA512Encoder < HashEncoder
  def initialize
    super
    self.module_name = 'SHA512 Encoder'
  end

  def hash_function(string)
    OpenSSL::Digest::SHA512.new.hexdigest(string)
  end
end

SHA512Encoder.new.run
