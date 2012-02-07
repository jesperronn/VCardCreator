# Create Vcards from  Google Spreadsheet data #

Script to create VCards from a google spreadsheet, for easy import into Adress book, iPhone, etc.

Created by Jesper Rønn-Jensen 2012-02-06



## USAGE ##


 1. Run `bundle install` (to install dependencies) -- first time only!
 2. Copy `config.example.yml` to `config.yml` and add your details
 3. Run the script with `ruby build.rb`


## EXAMPLE ##

I created a public Google spreadsheet with the proper columns, which can be copied and used

https://docs.google.com/spreadsheet/ccc?key=0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c&hl=da#gid=0

Note that the key is typically what you need when you add details into `config.yml`

For this example, the key is `0AuL6dmTSZWRVdEtnUUlKM1ppM25HTTFkVVJYZXhrV3c`

