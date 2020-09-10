class PagesController < ApplicationController 
  
  def add_requests_in_queue
    rand_delay = rand(20)
    sleep rand_delay
    res = {"request" => "added", "delay" => rand_delay}
    render :plain => res.to_json, status:200, content_type: "application/json"
  end
    
    




end