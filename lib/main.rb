require "selenium-webdriver"
require "pry"
require "pry-byebug"
require "csv"
require 'fileutils'

class Translink
  DOWNLOAD_PATH = "tmp/downloads"
  FILE_NAME = "Travel_history.csv"
  FILE_PATH = "#{DOWNLOAD_PATH}/#{FILE_NAME}"
  attr_reader :driver
  def initialize(file_path = FILE_PATH)
    @driver = initialize_driver
    @file_path = file_path
  end

  def initialize_driver
    options = Selenium::WebDriver::Chrome::Options.new
    # options = Selenium::WebDriver::Chrome::Options.new(args: ['headless'])
    Selenium::WebDriver.for(:chrome, options: options).tap do |driver|
      driver.download_path = DOWNLOAD_PATH
    end
  end

  def missed_touch_off?
    go_to_page
    fill_user_name_and_password
    download_newest_csv
    close
    search_for_unknown
  end

  private

  def go_to_page
    driver.get("https://gocard.translink.com.au/")
  end

  def fill_user_name_and_password
    driver.find_element(id: "CardNumber").send_keys(ENV["CARDNUMBER"])
    driver.find_element(id: "Password").send_keys(ENV["PASSWORD"])
    driver.find_element(css: "#login-buttons input").click
  end

  def download_newest_csv
    FileUtils.remove_dir(DOWNLOAD_PATH, true)
    today = Date.today
    driver.get("https://gocard.translink.com.au/webtix/cardinfo/history.do?csvExport=yes&startDate=#{format_date(today - 7)}&endDate=#{format_date(today)}")
  end

  def format_date(date)
    date.strftime("%d/%y/%Y")
  end

  TIME_COLUMN = "Time"
  MISSED_TAP_OFF = "unknown"

  def search_for_unknown
    CSV
      .read(@file_path, headers: true)[TIME_COLUMN]
      .map { |el| el&.downcase }
      .include?(MISSED_TAP_OFF)
  end

  def close
    driver.close
  end
end

if Translink.new.missed_touch_off?
  exit 1
else
  exit 0
end
