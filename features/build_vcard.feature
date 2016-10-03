Feature: Build a VCard
  In order create vcard from downloaded data

  @announce
  Scenario: One Simple vcard
    Given a file named "config_test.yml" with:
"""yml
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
"""

    And a file named ".cache/worksheet.yml" with:
"""yaml
---
- - No.
  - Title
  - ''
  - First name
  - Last name
  - email
  - Birthday
  - Age
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
  - Linkedin link
  - Skype ID
  - jabber id (chat)
  - twitter id
- - '1'
  - Front desk clerk
  - ''
  - Philip Seymor
  - Hoffmann
  - sh
  - 13/07/1967
  - '1110 Memory lane'
  - 90210
  - Beverly Hills
  - ''
  - '555-cellphone'
  - '555-alt-phone'
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - ''
  - 'http://linkedin.com/in/philip-seymor'
  - 'my-skype-name'
  - 'my-jabber-name'
  - "@my-twitter-name"
"""
    When I run `build --config config_test.yml --local --debug`

    * the output should contain "Worksheet contents (2 rows)"
    * the output should contain "Loading config from file"
    * a file named "vcards/Philip Seymor Hoffmann.vcf" should exist
    * the file "vcards/Philip Seymor Hoffmann.vcf" should contain:
      """
      BEGIN:VCARD
      VERSION:3.0
      PROFILE:VCARD
      N;CHARSET=iso-8859-1:Hoffmann;Philip Seymor
      FN;CHARSET=iso-8859-1: Philip Seymor Hoffmann
      ORG:Nine A/S
      """
    * the file "vcards/Philip Seymor Hoffmann.vcf" should contain:
      """
      TEL;type=CELL;type=VOICE;type=pref: 555-cellphone
      TEL;type=HOME;type=VOICE: 555-alt-phone
      EMAIL:sh@nine.dk
      BDAY:1967-07-13
      """
    * the file "vcards/Philip Seymor Hoffmann.vcf" should contain:
      """
      X-SOCIALPROFILE;type=linkedin:http://linkedin.com/in/philip-seymor
      X-SOCIALPROFILE;type=twitter:http://twitter.com/#!/my-twitter-name
      item1.IMPP;X-SERVICE-TYPE=Skype:skype:my-skype-name
      """
    * the file "vcards/Philip Seymor Hoffmann.vcf" should contain:
      """
      NOTE: Start date -
      """
    * the file "vcards/Philip Seymor Hoffmann.vcf" should contain:
      """
      PHOTO;ENCODING=b;TYPE=JPEG:
      END:VCARD
      """
