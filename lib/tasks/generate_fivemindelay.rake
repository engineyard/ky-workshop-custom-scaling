namespace :fivemindelay do
  desc "Generate Fivemindelay jobs"
  task :generate => :environment do
    job_count = ENV['FIVEMINDELAY_JOB_COUNT'].to_i || 10
    queue_name = ENV['FIVEMINDELAY_JOB_QUEUE'] || :default
    puts "Generating #{job_count} jobs..."
    job_count.times{ FivemindelayJob.set(queue: queue_name).perform_later }
  end
end
