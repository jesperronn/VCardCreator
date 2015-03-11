# VCard class must contain the actual generation of the card.
# it should read values from a Contact object
class VCard
  @country_code = '+45'

  def initialize(contact, photo_folder)
    @contact = contact
    @photo_folder  = photo_folder
  end

  def twitter
    # remember to remove any @-signs from the twitter name in url
    twit_url = "http://twitter.com/#!/#{@contact.twitter.gsub(/^\@/, '')}"
    return '' if @contact.twitter.empty?
    "X-SOCIALPROFILE;type=twitter:#{twit_url}\n"
  end

  def linkedin
    # remember to remove any @-signs from the linkedin name in url
    return '' if @contact.linkedin.empty?
    "X-SOCIALPROFILE;type=linkedin:#{@contact.linkedin}\n"
  end

  def skype
    return '' if @contact.skype.empty?
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
    <<-ENDNOTE
    NOTE: Start date - #{@contact.start_date}
    ENDNOTE
  end

  def photo
    filename = "#{@photo_folder}/#{@contact.initials}.jpg"
    # puts "#{@contact.initials} exists? #{File.exists?(filename)}"
    return unless File.exist?(filename)
    file_contents = File.read(filename)
    Base64.strict_encode64(file_contents)
  end

  def to_vcard
    <<-ENDVCARD.gsub(/^\s+/, '')
                  BEGIN:VCARD
                  VERSION:3.0
                  PROFILE:VCARD
                  N;CHARSET=iso-8859-1:#{@contact.last_name};#{@contact.first_name}
                  FN;CHARSET=iso-8859-1: #{@contact.name}
                  ORG:#{@contact.org}
                  #{phone}
                  #{alt_phone}
                  EMAIL:#{@contact.email}
                  #{birthday}
                  #{linkedin}
                  #{twitter}
                  #{skype}
                  #{note}
                  PHOTO;ENCODING=b;TYPE=JPEG:#{photo}
                  END:VCARD
                  ENDVCARD
  end
end
