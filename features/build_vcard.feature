Feature: Build a VCard
  In order create vcard from downloaded data

  @announce
  Scenario: One Simple vcard
    Given a file named "config_test.yml" with:
    """
columns:
  - :first_name:  "D"
  - :last_name:   "E"
  - :initials:    "F"
  - :birthday:    "G"
  - :phone:       "L"
  - :alt_phone:   "M"
  - :start_date:  "N"
  - :resign_date: "O"
  - :linkedin:    "U"
  - :skype:       "V"
  - :jabber:      "W"
  - :twitter:     "X"

# first content rows: (index is 0-based)
start_row: 1
resigned_contacts:
  -

zip_file_name: vcardbuilder-vcards
cache_file_name: .cache/worksheet.yml
photo_cache: .cache/photos
output_folder: vcards

spreadsheet_key: 0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c
account: example@gmail.com
password: "my_google_password"
    """

    And a file named ".cache/worksheet.yml" with:
    """
---
- - No.
  - Title
  - First name
  - Last name
  - email
  - Birthday
  - Address
  - Postal code
  - City
  - Cell phone
  - Alternative phone (private)
  - Start date
  - End date
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
  - '1110 Memory lane'
  - 90210
  - Beverly Hills
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
  - 'http://linkedin.com/in/philip-seymor'
  - 'my-skype-name'
  - 'my-jabber-name'
  - "@pshoff"
    """
    When I run `build --config config_test.yml --local --debug`
    Then the output should contain "Loading config from file"
    # Then I should see a file named "vcards/Seymor Hoffmann.vcf"
