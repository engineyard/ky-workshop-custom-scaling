namespace :complex do
  desc "Generate Complex jobs"
  task :generate => :environment do
    job_count = ENV['COMPLEX_JOB_COUNT'].to_i || 10
    puts "Generating #{job_count} jobs..."
    job_count.times{ ComplexJob.perform_later }
  end
end