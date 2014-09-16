# Create Vcards from  Google Spreadsheet data #

Script to create VCards from a google spreadsheet, for easy import into
Mac Adressbook, iPhone, etc.

Created by Jesper Rønn-Jensen 2012-02-06



## Usage ##


 1. Run `bundle install` (to install dependencies) -- first time only!
 2. Copy `config.example.yml` to `config.yml` and add your details
 3. Run the script with `./build.rb` (or on windows `ruby build.rb`)


## Integration with iPhone/Mac addresbook
I have some notes (in Danish for now) describing how I install/update phone numbers
on my iPhone and Mac addressbook. See [INSTRUCTIONS.erb.md](INSTRUCTIONS.erb.md).

## Example file ##

I created a public Google spreadsheet with the proper columns, which can be copied and used

https://docs.google.com/spreadsheet/ccc?key=0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c&hl=da#gid=0

Note that the key is typically what you need when you add details into `config.yml`

For this example, the key is `0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c`



The output is a series of vcards (one per person found in the spreadsheet).
You will also find a **zip-file packed with all vcards** for easy sharing.

## Vcard format

The vcards contain:

 * image
 * name
 * company name
 * email
 * birthday (so you get a birthday reminder)
 * phone number (home, work)
 * skype id
 * twitter id

## Contributions

Contributions are welcome, please just fork project and send pull requests.
