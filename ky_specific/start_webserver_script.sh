#!/bin/bash

# Start the Rack webserver that will server "/metrics" route
bundle exec rackup --debug --host 0.0.0.0 --daemonize ./ky_specific/passenger_metrics_config.ru

# We can pass some environment variables in order to configure the workers count 
WORKERS_MIN=${passenger_min_instances:-2}
WORKERS_MAX=${passenger_max_pool_size:-6}

# Start Passenger Standalone webserver with customized nginx template.
# The customization includes that the "/metrics" will be served from the Rack webserver
passenger start --port 5000 --min-instances $WORKERS_MIN --max-pool-size $WORKERS_MAX --nginx-config-template ./ky_specific/passenger_standalone_nginx_config.erb
