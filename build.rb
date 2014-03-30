#!/usr/bin/env ruby
# encoding: UTF-8
require "rubygems"
require "google_spreadsheet"
require 'fileutils'
require 'digest/md5'
require 'yaml'

class Conf
  attr_accessor :start_row, :worksheet, :resigned_contacts
  #raw_config = File.read("config.yml")
  APP_CONFIG = YAML.load_file("config.yml")
  #p APP_CONFIG


  #columns for this spreadsheet
  @@columns  = {
    :first_name =>  1,
    :last_name  =>  2,
    :phone      =>  13,
    :alt_phone  =>  14,
    :email      =>  16,
    :skype      =>  10,
    :jabber     =>  11,
    :twitter    =>  12
  }

  def initialize
    # Logs in.
    # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details.
    session = GoogleSpreadsheet.login(APP_CONFIG["account"], APP_CONFIG["account_password"])

    #retrieve the worksheet
    @worksheet = session.spreadsheet_by_key(APP_CONFIG["spreadsheet_key"]).worksheets[0]

    #first content rows: (index is 1-based)
    @start_row = 3

    ## initials of resigned employees -- will be ignored and not generated
    @resigned_contacts     = %w(thm mbw el pfa)

  end

  def get_columns
    @@columns
  end
end

class Contact
  @@org                   = "NineConsult A/S"
  @@email_suffix          = "@nineconsult.dk"
  @@gravatar_email_suffix = "@nineconsult.dk"

  attr_accessor :name, :first_name, :last_name, :initials, :phone, :alt_phone, :skype, :jabber, :twitter, :org, :resigned
  #initialize a contact with with values from the worksheet row

  def initialize(config, ws, row)
    idx      = config.get_columns
#    p ws
#    p row
#    p idx[:first_name]
    @first_name = ws[row, idx[:first_name]]
    @last_name  = ws[row, idx[:last_name]]
    @name       = "#{@first_name} #{@last_name}"
    @initials   = ws[row, idx[:email]]
    @phone      = ws[row, idx[:phone]]
    @alt_phone  = ws[row, idx[:alt_phone]]
    @email      = ws[row, idx[:email]]
    @skype      = ws[row, idx[:skype]]
    @jabber     = ws[row, idx[:jabber]]
    @twitter    = ws[row, idx[:twitter]]
    @org        = @@org

    @resigned = config.resigned_contacts.include? @initials
  end

  #valid contacts must have name and email present
  def valid?
    !(@initials.empty? || @first_name.empty? || @last_name.empty?)
  end

  #returns a gravatar url based on the email address
  def photo_url
    mail_nine_dk = @email.strip.downcase + @@gravatar_email_suffix
    mail_hash = Digest::MD5.hexdigest(mail_nine_dk)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=150"
  end

  #returns full email address
  def email
    @email + @@email_suffix
  end


end

# VCard class must contain the actual generation of the card.
# it should read values from a Contact object
class VCard
  @@country_code = "+45"

  def initialize(contact)
    @contact = contact
  end

  def twitter
    #remember to remove any @-signs from the twitter name in url
    twit_url ="http://twitter.com/#!/#{@contact.twitter.gsub(/^\@/, "")}"
    if @contact.twitter.empty?
      ""
      else
      "X-SOCIALPROFILE;type=twitter:#{twit_url}\n"
    end
  end


  def skype
    if @contact.skype.empty?
      ""
    else
      #"X-SERVICE-SKYPE:Skype:#{@contact.skype}\n"
      "item1.IMPP;X-SERVICE-TYPE=Skype:skype:#{@contact.skype}\n"

    end
  end

  def phone
    if @contact.phone.empty?
      "TEL;type=CELL;type=VOICE:"
    else
      "TEL;type=CELL;type=VOICE;type=pref:#{@@country_code} #{@contact.phone}"
    end
  end

  def alt_phone
    if @contact.alt_phone.empty?
      ""
    else
      "TEL;type=HOME;type=VOICE:#{@@country_code} #{@contact.alt_phone}\n"
    end
  end

  def photo
    filename = ".photo_cache/#{@contact.initials}.jpg"
    #puts "#{@contact.initials} exists? #{File.exists?(filename)}"
    if File.exists?(filename)
      file_contents = File.read(filename)
      Base64.strict_encode64(file_contents)
      #file_contents.split('\n').each{|line| line.prepend(' ')}
    end
  end

  def to_vcard()
    #debugger
    first_part    = <<-ENDVCARD.gsub(/^\s+/, "")
                    BEGIN:VCARD
                    VERSION:3.0
                    N:#{@contact.last_name};#{@contact.first_name};;;
                    FN: #{@contact.name}
                    ORG:#{@contact.org}
                    #{phone}
                    EMAIL:#{@contact.email}
                    PHOTO;ENCODING=b;TYPE=JPEG:#{photo}
                    ENDVCARD



    last_part    = <<-ENDVCARD.gsub(/^\s+/, '')
                    END:VCARD
                    ENDVCARD
    first_part + alt_phone + twitter + skype + last_part
  end

end

class Worksheeter

  def initialize(config)
    @ws = config.worksheet
    @config = config

    FileUtils.mkdir_p 'vcards'
    FileUtils.mkdir_p '.photo_cache'
  end

  def generate_vcards
    #debugstuff()
    for row in get_items
      contact = Contact.new(@config, @ws, row)
     # p contact.name


      #only create vcards for the "valid" rows in spreadsheet:
      #valid contacts must have name and email present
      if contact.valid? && !contact.resigned
        filename = "vcards/#{row}_#{contact.name}.vcf"
        File.open(filename, "w") do |f|
          f.write( VCard.new(contact).to_vcard() )
        end
      end
    end
  end

  def fetch_photos

    for row in get_items
      contact = Contact.new(@config, @ws, row)
      if contact.valid?
        puts "fetching #{contact.initials}: #{contact.photo_url}"
        %x(curl -s #{contact.photo_url} > .photo_cache/#{contact.initials}.jpg )
      end
    end
  end

  def zip_folder
    %x(zip vcards-#{ Date.today.to_s  }.zip vcards)
  end

  def get_items
    @config.start_row..@ws.num_rows
  end


end



config = Conf.new
ws = Worksheeter.new(config)
ws.fetch_photos
ws.generate_vcards
ws.zip_folder