# Crawler in Ruby

## Product crawler on Amazon

___

### Link to demo: [demo](https://drive.google.com/file/d/1R3YdDPRqz8lqqQGLyhXdYVzBpsPp9ily/view?usp=sharing)

### Libraries (modules) used:
- **Nokogiri** (*HTML parser*)
- **HTTPParty** (*user-friendly HTTP client*)
- **Sequel** (*database toolkit*)
- **Sqlite3** (*to use sqlite3 engine*)

### Requirements (versions used):
- **Ruby** version: 3.3.0
- **Sqlite3** version: 3.45.0
- **Nokogiri** version: 1.16.0-x64-mingw-ucrt
- **HTTPParty** version: 0.21.0
- **Sequel** version: 5.76.0
- **Sqlite3** version: 1.7.0-x64-mingw-ucrt

### Features
- Download basic product data (title, price, image url)
- Download basic product data by keywords
- Download detailed product data, which is visible only on the product subpage
- Download product links (urls)
- Save data in a database via Sequel

### Useful information

**Install gems:**
````
gem install httparty
gem install nokogiri
gem install sequel
gem install sqlite3
````

**Create sqlite3 DB (Windows cmd):**
````
> cd [db_directory]
> sqlite3 [db_name.db]
````

**Make the .db file visible**
````
sqlite> .databases
````
