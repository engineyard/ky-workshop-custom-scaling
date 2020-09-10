require 'open-uri'

class ComplexJob < ApplicationJob
  queue_as :default

  def perform(*args)
    sleep(rand(1..30))
    open("http://www.ruby-lang.org/") {|f|
      f.each_line {|line| p line}
    }
  end
end
