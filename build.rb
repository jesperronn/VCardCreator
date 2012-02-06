# encoding: UTF-8
require "rubygems"
require "google_spreadsheet"
require 'fileutils'
require 'digest/md5'
require 'yaml'

class Conf
#  attr_accessor :worksheet
  #raw_config = File.read("config.yml")
  APP_CONFIG = YAML.load_file("config.yml")
  #p APP_CONFIG

  #columns for this spreadsheet
  @@columns  = {
    :first_name =>  1,
    :last_name  =>  2,
    :phone      =>  9,
    :email      => 11,
    :skype      =>  6,
    :jabber     =>  7,
    :twitter    =>  8
  }

  def initialize
    # Logs in.
    # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details.
    session = GoogleSpreadsheet.login(APP_CONFIG["account"], APP_CONFIG["account_password"])

    #retrieve the worksheet
    @worksheet = session.spreadsheet_by_key(APP_CONFIG["spreadsheet_key"]).worksheets[0]

  end

  def get_worksheet
    @worksheet
  end

  def get_columns
    @@columns
  end
end

class Contact
  @@email_suffix = "@nineconsult.dk"
  @@org          = "NineConsult A/S"

  attr_accessor :name, :first_name, :last_name, :phone, :skype, :jabber,:twitter, :org
  #initialize a contact with with values from the worksheet row

  def initialize(config, ws, row)
    idx      = config.get_columns
#    p ws
#    p row
#    p idx[:first_name]
    @first_name = ws[row, idx[:first_name]]
    @last_name  = ws[row, idx[:last_name]]
    @name       = "#{@first_name} #{@last_name}"
    @phone      = ws[row, idx[:phone]]
    @email      = ws[row, idx[:email]]
    @skype      = ws[row, idx[:skype]]
    @jabber     = ws[row, idx[:jabber]]
    @twitter    = ws[row, idx[:twitter]]
    @org        = @@org
  end


  #returns a gravatar url based on the email address
  def photo
    mail_hash = Digest::MD5.hexdigest(@email.strip.downcase)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=120"
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


  def to_vcard()

    first_part    = <<-ENDVCARD.gsub(/^\s+/, "")
                    BEGIN:VCARD
                    VERSION:3.0
                    N:#{@contact.last_name};#{@contact.first_name};;;
                    FN: #{@contact.name}
                    ORG:#{@contact.org}
                    TEL;type=CELL;type=VOICE;type=pref:#{@@country_code} #{@contact.phone}
                    EMAIL:#{@contact.email}
                    PHOTO:#{@contact.photo}
                    ENDVCARD



    last_part    = <<-ENDVCARD.gsub(/^\s+/, "")
                    END:VCARD
                    ENDVCARD
    first_part + twitter + skype + last_part
  end

end

class Worksheeter

  def initialize(config)


    #range of content rows: (index is 1-based)
    @content = (3..20)

    @ws =config.get_worksheet
    @config =config

    FileUtils.mkdir_p 'vcards'
  end

  def run()
    #debugstuff()
    for row in @content.min..@ws.num_rows
      contact = Contact.new(@config, @ws, row)
     # p contact.name

      filename = "vcards/#{row}_#{contact.name}.vcf"
      File.open(filename, "w") do |f|     
        f.write( VCard.new(contact).to_vcard() )
      end
    end
  end




end



config = Conf.new
Worksheeter.new(config).run()