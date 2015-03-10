Feature: Build a VCard
  In order create vcard from downloaded data

  Scenario: One Simple vcard
    Given the file "config.yml" with the following content:
    """
columns:
  - :first_name:  "D"
  - :last_name:   "E"
  - :birthday:    "G"
  - :phone:       "N"
  - :alt_phone:   "O"
  - :initials:    "F"
  - :start_date:  "P"
  - :resign_date: "Q"
  - :linkedin:    "AD"
  - :skype:       "AE"
  - :jabber:      "AF"
  - :twitter:     "AG"

# first content rows: (index is 0-based)
start_row: 0
resigned_contacts:
  -

zip_file_name: vcardbuilder-vcards
spreadsheet_key: 0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c
account: example@gmail.com
password: "my_google_password"
    """

    And a file named ".cache/worksheet.yml" with the following content:
    """
---
- - No.
  - Titel
  - x
  - First name
  - Last name
  - email
  - Birthday
  - ''
  - Address
  - Postal code
  - City
  - ''
  - ''
  - Cell phone
  - |-
    Alternative
    phone (private)
  - Start date
  - End date
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - Linkedin link
  - Skype ID
  - jabber id (chat)
  - twitter id
- - '1'
  - Front desk clerk
  - ''
  - Seymor
  - Hoffmann
  - sh
  - 10/01/1910
  - ''
  - '1110 Memory lane'
  - 90210
  - Beverly Hills
  - ''
  - ''
  - '555-3344'
  - ''
  - 01/07/2007
  - ''
  -
  -
  -
  -
  -
  -
  - ''
  -
  - ''
  -
  - ''
  - ''
  - 'http://linkedin.com/in/philip-seymor'
  - 'my-skype-name'
  - 'my-jabber-name'
  - "@pshoff"
    """
    When I build
    Then I should see a file named "vcards/Seymor Hoffmann.vcf"
