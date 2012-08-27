#!/usr/bin/env ruby
require 'rubygems'
require 'prawn'
require 'selenium-webdriver'
require 'pry'
require 'yaml'
require 'uri'

class Zisui
  def initialize
    @driver = Selenium::WebDriver.for :firefox
    @imgs = []
  end

  def login(auth)
    @driver.get auth['login_url']
    auth['form'].each do |id, value|
      element = @driver.find_element :id => id
      element.send_keys value
    end
    element = @driver.find_element :id => auth['submit']
    element.submit
  end

  def split_img(img)
    width, height = `identify '#{img}.jpg'`.split(/\s/).select{|i|
      i =~ /^\d+x\d+$/
    }.first.split('x').map{|i| i.to_i}

    puts "#{width}x#{height}"
    w = width
    h = (w*1.41).to_i

    0.upto(height/h) do |i|
      puts fname = "#{img}_#{i}.jpg"
      puts cmd = "convert -quality 95 -crop #{w}x#{h}+0+#{h*i} #{img}.jpg #{fname}"
      system cmd
    end
    height/h + 1
  end

  def load(page)
    uri = URI.parse(page)
    @driver.get page
    file = "/tmp/#{uri.path.split('/')[-1]}"
    @driver.save_screenshot "#{file}.jpg"
    i = split_img file
    @imgs << i.times.map { |i| "#{file}_#{i}.jpg" }
  end

  def output(path)
    @driver.quit
    imgs = @imgs.flatten
    Prawn::Document.generate(path) do
      imgs.flatten.each do |img|
        #image(img,
        #      :fit => [bounds.absolute_right - bounds.absolute_left,
        #               bounds.absolute_top - bounds.absolute_bottom]
        #      )
        image img, :at => [-1*bounds.absolute_left, bounds.absolute_top], :fit => [bounds.absolute_right+bounds.absolute_left, bounds.absolute_top+bounds.absolute_bottom]
        start_new_page
      end
    end
  end

  def quit
  end
end

config  = YAML.load_file('config.yml')

zisui = Zisui.new
zisui.login config['auth']
config['list'].each do |url|
  zisui.load url
end
zisui.output config['output']
