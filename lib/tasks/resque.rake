# Resque tasks
require 'resque/tasks'
require 'resque_scheduler/tasks'

# Start a worker with proper env vars and output redirection
def run_worker(queue, count = 1)
  puts "Starting #{count} worker(s) with QUEUE: #{queue}"
  ops = {:pgroup => true, :err => [(Rails.root + "log/workers_error.log").to_s, "a"],
                          :out => [(Rails.root + "log/workers.log").to_s, "a"]}
  env_vars = {"QUEUE" => queue.to_s}
  count.times {
    pid = spawn(env_vars, "rake resque:work", ops)
    Process.detach(pid)
  }
end

# Start a scheduler, requires resque_scheduler >= 2.0.0.f
def run_scheduler
  puts "Starting resque scheduler"
  env_vars = {
    "BACKGROUND" => "1",
    "PIDFILE" => (Rails.root + "tmp/pids/resque_scheduler.pid").to_s,
    "VERBOSE" => "1"
  }
  ops = {:pgroup => true, :err => [(Rails.root + "log/scheduler_error.log").to_s, "a"],
                          :out => [(Rails.root + "log/scheduler.log").to_s, "a"]}
  pid = spawn(env_vars, "rake resque:scheduler", ops)
  Process.detach(pid)
end

namespace :resque do
  desc "Setup resque scheduler"
  task :setup => :environment do
    require 'resque'
    require 'resque_scheduler'
    require 'resque/scheduler'
    Resque.redis = 'localhost:6379'
    Resque.schedule = YAML.load_file("#{Rails.root}/config/resque_schedule.yml")
  end

  desc "Restart running workers"
  task :restart_workers => :environment do
    Rake::Task['resque:stop_workers'].invoke
    Rake::Task['resque:start_workers'].invoke
  end

  desc "Quit running workers"
  task :stop_workers => :environment do
    pids = []
    Resque.workers.each do |worker|
      # pids.concat(worker.worker_pids)
      pids << worker.to_s.split(":")[1]
    end
    if pids.empty?
      puts "No workers to kill"
    else
      syscmd = "kill -s QUIT #{pids.join(' ')}"
      puts "Running syscmd: #{syscmd}"
      system(syscmd)
    end
  end

  desc "Start workers"
  task :start_workers => :environment do
    run_worker("*", 1)
    # run_worker("high", 1)
  end

  desc "Restart scheduler"
  task :restart_scheduler => :environment do
    Rake::Task['resque:stop_scheduler'].invoke
    Rake::Task['resque:start_scheduler'].invoke
  end

  desc "Quit scheduler"
  task :stop_scheduler => :environment do
    pidfile = Rails.root + "tmp/pids/resque_scheduler.pid"
    if !File.exists?(pidfile)
      puts "Scheduler not running"
    else
      pid = File.read(pidfile).to_i
      syscmd = "kill -s QUIT #{pid}"
      puts "Running syscmd: #{syscmd}"
      system(syscmd)
      FileUtils.rm_f(pidfile)
    end
  end

  desc "Start scheduler"
  task :start_scheduler => :environment do
    run_scheduler
  end

  desc "Reload schedule"
  task :reload_schedule => :environment do
    pidfile = Rails.root + "tmp/pids/resque_scheduler.pid"
    if !File.exists?(pidfile)
      puts "Scheduler not running"
    else
      pid = File.read(pidfile).to_i
      syscmd = "kill -s USR2 #{pid}"
      puts "Running syscmd: #{syscmd}"
      system(syscmd)
    end
  end
end