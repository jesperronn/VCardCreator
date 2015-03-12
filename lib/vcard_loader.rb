# encoding: UTF-8
require 'rubygems'
require 'fileutils'
require 'digest/md5'
require 'erb'
require 'yaml'
require 'pp'
require 'pry'
require 'i18n'
require 'optparse'

Dir[__dir__ + '/vcard/*.rb'].each do |f|
  filename = f.sub(__dir__, '.')
  require_relative filename
end
