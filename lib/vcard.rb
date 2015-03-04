# VCard class must contain the actual generation of the card.
# it should read values from a Contact object
class VCard
  @country_code = '+45'

  def initialize(contact)
    @contact = contact
  end

  def twitter
    # remember to remove any @-signs from the twitter name in url
    twit_url = "http://twitter.com/#!/#{@contact.twitter.gsub(/^\@/, '')}"
    return '' if @contact.twitter.empty?

    "X-SOCIALPROFILE;type=twitter:#{twit_url}\n"
  end

  def skype
    return '' if @contact.skype.empty?

    # "X-SERVICE-SKYPE:Skype:#{@contact.skype}\n"
    "item1.IMPP;X-SERVICE-TYPE=Skype:skype:#{@contact.skype}\n"
  end

  def phone
    return 'TEL;type=CELL;type=VOICE:' if @contact.phone.empty?

    "TEL;type=CELL;type=VOICE;type=pref:#{@country_code} #{@contact.phone}"
  end

  def alt_phone
    return '' if @contact.alt_phone.empty?

    "TEL;type=HOME;type=VOICE:#{@country_code} #{@contact.alt_phone}\n"
  end

  def birthday
    return '' if @contact.birthday.empty?

    "BDAY:#{ Date.parse(@contact.birthday) }"
  end

  # put anything in the note that you see fit.
  # for now, it's the company start date
  def note
    "NOTE: Start date - #{@contact.start_date}"
  end

  def photo
    filename = ".photo_cache/#{@contact.initials}.jpg"
    # puts "#{@contact.initials} exists? #{File.exists?(filename)}"
    return unless File.exist?(filename)
    file_contents = File.read(filename)
    Base64.strict_encode64(file_contents)
  end

  def to_vcard
    first_part  = <<-ENDVCARD.gsub(/^\s+/, '')
                  BEGIN:VCARD
                  VERSION:3.0
                  N;CHARSET=iso-8859-1:#{@contact.last_name};#{@contact.first_name};;;
                  FN;CHARSET=iso-8859-1: #{@contact.name}
                  ORG:#{@contact.org}
                  #{phone}
                  #{alt_phone}
                  EMAIL:#{@contact.email}
                  #{birthday}
                  #{twitter}
                  #{skype}
                  #{note}
                  PHOTO;ENCODING=b;TYPE=JPEG:#{photo}
                  ENDVCARD

    last_part = <<-ENDVCARD.gsub(/^\s+/, '')
                END:VCARD
                ENDVCARD
    first_part + last_part
  end
end
