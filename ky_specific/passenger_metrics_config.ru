require 'sidekiq'
require 'sidekiq/api'

class Application
    def call(env)
      status  = 200
      headers = { "Content-Type" => "text/plain; version=0.0.4", "Cache-Control" => "no-cache" }
  
      output = `/usr/local/bundle/gems/passenger-5.3.7/bin/passenger-status`
      passenger_queue = output.scan(/Requests in queue: [0-9]*/)[0].strip.split(": ")[1].to_i
      passenger_workers = output.scan(/PID/).length
      passenger_metrics_string = "# Passenger metrics\npassenger_requests_queue #{passenger_queue.to_s}\npassenger_workers #{passenger_workers.to_s}"
  
      metrics = {
        "sidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0},
        #"altsidekiq" => { "total_workers" => 0, "total_threads" => 0, "busy_threads" => 0, "busy_percentage" => 0.0}
      }   
        
      metrics_string = "# Sidekiq metrics\n"
      metrics.keys.each do |process_name|
        begin 
          ps = Sidekiq::ProcessSet.new
          metrics[process_name]["total_workers"] = ps.map { |host| 1 if host["identity"].split("-")[-3]==process_name}.map { |item| item.to_i }.sum
          metrics[process_name]["total_threads"] = ps.map { |host| host['concurrency'].to_i if host["identity"].split("-")[-3]==process_name }.map { |item| item.to_i }.sum 
          metrics[process_name]["busy_threads"] = ps.map { |host| host['busy'].to_i if host["identity"].split("-")[-3]==process_name }.map { |item| item.to_i}.sum 
          metrics[process_name]["busy_percentage"] = (100.0 * (metrics[process_name]["busy_threads"].to_f / [metrics[process_name]["total_threads"], 1].max.to_f)).to_i   
          metrics_string += "#{process_name}_total_workers #{metrics[process_name]["total_workers"]}\n#{process_name}_total_threads #{metrics[process_name]["total_threads"]}\n#{process_name}_busy_threads #{metrics[process_name]["busy_threads"]}\n#{process_name}_busy_percentage #{metrics[process_name]["busy_percentage"]}\n"
        rescue Exception
          metrics_string += "# No stats for sidekiq! Are any sidekiq workers running?\n"
        end
      end
      
      metrics_string += passenger_metrics_string
        
      body    = ["# this is served from rack server\n#{metrics_string}"]
  
      [status, headers, body]
    end
  end
  
run Application.new