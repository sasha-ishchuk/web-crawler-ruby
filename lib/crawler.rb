require "httparty"
require "nokogiri"
require 'sequel'
require 'sqlite3'


# defining a data structure to store the scraped data
AmazonProduct = Struct.new(:url, :image, :name, :price, :details)
ProductDetails = Struct.new(:lang, :model_nr, :country_of_origin, :rating_avg, :reviews_num)

DataBase = Sequel.connect('sqlite://sqlite3-db/amazon.db')

def get_data(base_url, url, is_keywords)

  products = []

  response = HTTParty.get(base_url.concat(url), {
    headers: {
      "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
    },
  })

  # print response code
  puts response.code

  # parsing the HTML document returned by the server
  document = Nokogiri::HTML(response.body)

  if is_keywords
    # parse search results
    document.css('[data-component-type="s-search-result"]').each do |result|
      # Wyciągamy potrzebne informacje
      product_url = result.css('a.a-link-normal.s-no-outline')[0]['href']
      product_name = result.css('span.a-size-base-plus.a-color-base.a-text-normal').text.strip
      image_url = result.css('div.s-product-image-container img.s-image')[0]['src']
      price_element = result.css('span.a-offscreen')[0]

      # get price
      if price_element
        price = price_element.text&.strip
        price.slice!(-3..-1) if price
      else
        price = ""
      end

      # fix url
      product_url = "https://www.amazon.pl".concat(product_url)

      amazon_product = AmazonProduct.new(product_url, image_url, product_name, price)
      products.push(amazon_product)
    end
  else
    # parse category
    html_products = document.css("div.a-section.octopus-pc-card-content")
    products_list = html_products.css("ul")

    # iterate over the products
    products_list.each do |ul_element|
      ul_element.css("li").each do |li_element|

        url = li_element.css('a.octopus-pc-item-link').attr('href').value
        image = li_element.css('img.octopus-pc-item-image').attr('src').value
        name = li_element.css('div.octopus-pc-asin-title span.a-size-base').text.strip
        price = li_element.css('span.a-offscreen').first.text

        # fix url
        url = "https://www.amazon.pl".concat(url)

        # fix price
        match = price.match(/>([\d,]+)\s*zł<\//)
        price = match[1] if match
        price.slice!(-3..-1)

        amazon_product = AmazonProduct.new(url, image, name, price)
        products.push(amazon_product)

      end
    end
  end

  products.each do |item|
    product_url = item.url
    product_response = HTTParty.get(product_url, {
      headers: {
        "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
      },
    })

    # parsing the product detailed information
    product_doc = Nokogiri::HTML(product_response.body)
    details_section = product_doc.css('ul.detail-bullet-list')

    product_details = ProductDetails.new

    details_section.css('li span.a-list-item').each do |el|
      key = el.css('span.a-text-bold').text.strip
      if key.include?("Język")
        product_details.lang = el.css('span:not(.a-text-bold)').text.strip
      elsif key.include?("Numer modelu")
        product_details.model_nr = el.css('span:not(.a-text-bold)').text.strip
      elsif key.include?("Kraj pochodzenia")
        product_details.country_of_origin = el.css('span:not(.a-text-bold)').text.strip
      end
    end

    reviews_section = product_doc.css('div#detailBullets_averageCustomerReviews')
    product_details.rating_avg = reviews_section.css('span#acrPopover span.a-size-base').text.strip
    reviews = reviews_section.css('span#acrCustomerReviewText').text.strip.gsub("Liczba ocen: ", "")
    product_details.reviews_num = reviews.gsub(/\s/, '')
    item.details = product_details

    puts item

  end

  products
end

def get_products_data(base_url, url, keywords=[])
  products = []
  if keywords.empty?
    products = get_data(base_url, url, false)
  else
    search_url = "s?k=" + keywords.join("+")
    products = get_data(base_url, search_url, true)
  end
  products
end

def save_to_db(products_list)
  # create a table
  unless DataBase.table_exists?(:products)
    DataBase.create_table :products do
      primary_key :id
      column :name, String
      column :price, String
      column :image_url, String
      column :url, String
      column :lang, String
      column :model_nr, String
      column :country_of_origin, String
      column :rating_avg, String
      column :reviews_num, String
    end
  end

  puts "Item count in list: #{products_list.size}"

  # create a dataset from the table
  table = DataBase[:products]

  products_list.each do |item|
    # item details
    details = item.details
    # populate the table
    table.insert(name: item.name,
                 price: item.price,
                 image_url: item.image,
                 url: item.url,
                 lang: details.lang,
                 model_nr: details.model_nr,
                 country_of_origin: details.country_of_origin,
                 rating_avg: details.rating_avg,
                 reviews_num: details.reviews_num)
  end
  puts "Item count: #{table.count}"

end

def save_to_csv(products_list)
  # save data to the CSV file
  csv_headers = %w[url image name price details]
  CSV.open("output.csv", "wb", write_headers: true, headers: csv_headers) do |csv|
    products_list.each do |product_details|
      csv << product_details
    end
  end
end


def main
  # define main page to scrap (Amazon)
  base_url = "https://www.amazon.pl/"
  # define category (PS5 games, the most popular)
  games_url = "s?bbn=20930503031&rh=n%3A20659777031%2Cn%3A20930503031%2Cn%3A20930508031&dc&qid=1705757377&rnid=20930503031&ref=lp_20930503031_nr_n_1"

  # products = get_products_data(base_url, games_url)

  keywords_to_search = %w[sims 5 game]
  products = get_products_data(base_url, games_url, keywords_to_search)

  save_to_db(products)
  save_to_csv(products)
end

main
