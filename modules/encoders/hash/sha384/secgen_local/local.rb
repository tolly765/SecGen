#!/usr/bin/ruby
require_relative '../../../../../lib/objects/local_hash_encoder.rb'
require 'openssl'

class SHA384Encoder < HashEncoder
  def initialize
    super
    self.module_name = 'SHA384 Encoder'
  end

  def hash_function(string)
    OpenSSL::Digest::SHA384.new.hexdigest(string)
  end
end

SHA384Encoder.new.run
