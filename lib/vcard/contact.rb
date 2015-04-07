# Generates a Contact class for each employee
class Contact
  ORG                   = 'Nine A/S'
  EMAIL_SUFFIX          = '@nine.dk'
  GRAVATAR_EMAIL_SUFFIX = '@nineconsult.dk'

  # initialize a contact with with values from the worksheet row
  INITIAL_PROPS = [
    :first_name,
    :last_name,
    :initials,
    :phone,
    :alt_phone,
    :skype,
    :jabber,
    :twitter,
    :linkedin,
    :start_date,
    :birthday
  ]

  attr_accessor :name,
                :first_name,
                :last_name,
                :initials,
                :phone,
                :alt_phone,
                :skype,
                :jabber,
                :twitter,
                :linkedin,
                :start_date,
                :birthday,
                :org,
                :resigned,
                :row_num

  alias_method :resigned?, :resigned

  def initialize(config, row, num)
    # convert the columns array of hashes to one hash for easy lookup
    cols = config.columns.inject(:merge)
    unless row.nil?
      INITIAL_PROPS.each do |prop|
        fail "unknown config property '#{prop}'" unless cols[prop]

        send "#{prop}=", row[cols[prop].to_i]
      end
    end

    @name     = "#{@first_name} #{@last_name}"
    @email    = initials
    @org      = ORG
    @row_num  = num
    @resigned = config.resigned_contacts.include? @initials
  end

  # valid contacts must have name and email present
  def valid?
    !invalid?
  end

  # returns a gravatar url based on the email address
  def photo_url
    mail_nine_dk = @email.strip.downcase + GRAVATAR_EMAIL_SUFFIX
    mail_hash = Digest::MD5.hexdigest(mail_nine_dk)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=150"
  end

  # returns full email address
  def email
    "#{@email}#{EMAIL_SUFFIX}"
  end

  def pretty(format = :long)
    out = '#<' << self.class.to_s
    props = case format
            when :short
              %i(initials name)
            when :long
              %i(first_name last_name initials email row_num)
            else
              fail RuntimeError "format #{format} not recognized"
            end
    props.each do |prop|
      out << ' @' << "#{prop}='#{send prop}'"
    end
    out << '>'
  end

  def to_vcard(photo_folder)
    VCard.new(self, photo_folder).to_vcard
  end

  def write_to_file(config)
    File.open("#{config.output_folder}/#{filename}", 'w',
              external_encoding: Encoding::ISO_8859_1) do |f|
      f.write(to_vcard(config.photo_cache))
      Loggr.debug "wrote vcard for #{pretty(:short)}"
    end
  end

  private

  def invalid?
    [@initials, @first_name, @last_name].any? { |v| v.nil? || v.to_s.empty? }
  end

  def filename
    I18n.enforce_available_locales = false
    I18n.locale = :da
    I18n.transliterate "#{name}.vcf"
  end
end
