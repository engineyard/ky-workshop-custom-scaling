require "benchmark/memory"

FOO = []
class MemcrasherJob < ApplicationJob
    
    
    def perform(*args)
        Benchmark.memory do |x|
            x.report("mem_allocator_1") { mem_allocator_1 ; sleep(160)}
            #x.compare!
        end
    end
    
    def mem_allocator_1
        (1..9).each do |n|
          p "Iteration #{n}"
          100.times { FOO << {some: (0...rand(50)).map { ('a'..'z').to_a[rand(26)] }.join} }

        end
    end


end