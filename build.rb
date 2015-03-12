#!/usr/bin/env ruby
# encoding: UTF-8
lib_path = File.expand_path(File.dirname(__FILE__) + "/lib")
$LOAD_PATH.unshift lib_path unless $LOAD_PATH.include?(lib_path)

puts require_relative 'lib/vcard_loader'

VcardBuilder.new('config.yml').build
