class FivemindelayJob < ApplicationJob
    
    
    def perform(*args)
        sleep(60*5)
    end


end