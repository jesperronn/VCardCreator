# Generates a Contact class for each employee
class Contact
  ORG                   = 'NineConsult A/S'
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
                :start_date,
                :birthday,
                :org,
                :resigned,
                :row_num

  alias_method :resigned?, :resigned

  def initialize(config, ws, row)
    INITIAL_PROPS.each do |prop|
      fail "unknown config property '#{prop}'" unless config.columns[prop]
      send "#{prop}=", ws[row, config.columns[prop]]
    end

    @name     = "#{@first_name} #{@last_name}"
    @email    = initials
    @org      = ORG
    @row_num  = row
    @resigned = config.resigned_contacts.include? @initials
  end

  # valid contacts must have name and email present
  def valid?
    !(@initials.empty? || @first_name.empty? || @last_name.empty?)
  end

  # returns a gravatar url based on the email address
  def photo_url
    mail_nine_dk = @email.strip.downcase + GRAVATAR_EMAIL_SUFFIX
    mail_hash = Digest::MD5.hexdigest(mail_nine_dk)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=150"
  end

  # returns full email address
  def email
    @email + EMAIL_SUFFIX
  end

  def pretty_print(format = :long)
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
end
