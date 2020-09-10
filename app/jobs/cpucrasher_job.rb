require "benchmark/memory"

FOO = []
class CpucrasherJob < ApplicationJob
    
    def perform(*args)
        search_until = 800000
        (1..search_until).each do |i|
            if ( (is_prime? i) == true )
                p "#{i} is Prime number"
            end
        end
    end
    
    def is_prime?(num)
      return false if num <= 1
      Math.sqrt(num).to_i.downto(2).each {|i| return false if num % i == 0}
      true
    end


end