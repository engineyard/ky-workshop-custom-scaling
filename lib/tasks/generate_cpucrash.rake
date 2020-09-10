namespace :cpucrash do
  desc "Generate Memory Crasher jobs"
  task :generate => :environment do
    job_count = ENV['CPUCRASHER_JOB_COUNT'].to_i || 10
    puts "Generating #{job_count} jobs..."
    job_count.times{ CpucrasherJob.perform_later }
  end
end