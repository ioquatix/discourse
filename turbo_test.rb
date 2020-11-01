
ENV['RAILS_ENV'] = 'test'

worker do |index|
  ENV['TEST_ENV_NUMBER'] = index.to_s

  system("bin/rails", "db:drop", "db:create", "db:migrate")

  # Parallel spec system
  if ENV['RAILS_ENV'] == "test" && ENV['TEST_ENV_NUMBER']
    if ENV['TEST_ENV_NUMBER'] == ''
      n = 1
    else
      n = ENV['TEST_ENV_NUMBER'].to_i
    end
    
    port = 10000 + n
    
    Console.logger.info "Setting up parallel test mode - starting Redis #{n} on port #{port}"
    
    system("rm -rf tmp/test_data_#{n} && mkdir -p tmp/test_data_#{n}/redis")
    pid = Process.spawn("redis-server --dir tmp/test_data_#{n}/redis --port #{port}", out: "/dev/null")
    
    ENV["DISCOURSE_REDIS_PORT"] = port.to_s
    ENV["RAILS_DB"] = "discourse_test_#{n}"
    
    at_exit do
      Process.kill("SIGTERM", pid)
      Process.wait
    end
  end
  
  require_relative 'spec/rails_helper'
end
