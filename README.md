# Custom EYK HPA for Passenger and Sidekiq

This is a demo application that displays how the `Custom EYK HPA` can be used when it comes to web traffic and sidekiq jobs. Specifically, the application is using `passenger` webserver, but it could be used as an example in other cases too.

### Configuration

The application will use just SQLite. Since no communication is needed for our backend (no information shared among the webserver e.g. users etc), SQLite will do just fine. This means that the only configuration we should provide is the one regarding the `Custom EYK HPA`and redis.

* for redis:

```
REDIS_URL                                   redis://ec2-xxx-xxx-xxx-xxxredis://ec2-18-188-153-124.us-east-2.compute.amazonaws.com:6379/09.us-east-2.compute.amazonaws.com:6379/09
```

* for the `web` pods `Custom EYK HPA` we issue:

```
eyk config:set KY_AUTOSCALING_web_ENABLED=true KY_AUTOSCALING_web_MAX_REPLICAS=20 KY_AUTOSCALING_web_METRIC_NAME=passenger_workers KY_AUTOSCALING_web_METRIC_QUERY="avg(passenger_workers{service=\"<application's_name_here>\"})" KY_AUTOSCALING_web_METRIC_TYPE=Prometheus KY_AUTOSCALING_web_MIN_REPLICAS=3 KY_AUTOSCALING_web_TARGET_TYPE=Value KY_AUTOSCALING_web_TARGET_VALUE=4 --app=<application's_name_here>
```

which will result to: 

```
KY_AUTOSCALING_web_ENABLED                  true
KY_AUTOSCALING_web_MAX_REPLICAS             20
KY_AUTOSCALING_web_METRIC_NAME              passenger_workers
KY_AUTOSCALING_web_METRIC_QUERY             avg(passenger_workers{service="<application's_name_here>"})
KY_AUTOSCALING_web_METRIC_TYPE              Prometheus
KY_AUTOSCALING_web_MIN_REPLICAS             3
KY_AUTOSCALING_web_TARGET_TYPE              Value
KY_AUTOSCALING_web_TARGET_VALUE             4
```



* for the `sidekiq` pods `Custom EYK HPA` we issue:

```
eyk config:set KY_AUTOSCALING_sidekiq_ENABLED=true KY_AUTOSCALING_sidekiq_MAX_REPLICAS=20 KY_AUTOSCALING_sidekiq_METRIC_NAME=sidekiq_busy_percentage KY_AUTOSCALING_sidekiq_METRIC_QUERY="avg(sidekiq_busy_percentage{service=\"<application's_name_here>\"})" KY_AUTOSCALING_sidekiq_METRIC_TYPE=Prometheus KY_AUTOSCALING_sidekiq_MIN_REPLICAS=2 KY_AUTOSCALING_sidekiq_TARGET_TYPE=Value KY_AUTOSCALING_sidekiq_TARGET_VALUE=70 --app=<application's_name_here>
```

which will result to:

```
KY_AUTOSCALING_sidekiq_ENABLED                  true
KY_AUTOSCALING_sidekiq_MAX_REPLICAS             20
KY_AUTOSCALING_sidekiq_METRIC_NAME              sidekiq_busy_percentage
KY_AUTOSCALING_sidekiq_METRIC_QUERY             avg(sidekiq_busy_percentage{service="<application's_name_here>"})
KY_AUTOSCALING_sidekiq_METRIC_TYPE              Prometheus
KY_AUTOSCALING_sidekiq_MIN_REPLICAS             2
KY_AUTOSCALING_sidekiq_TARGET_TYPE              Value
KY_AUTOSCALING_sidekiq_TARGET_VALUE             70
```



### How it works

The application exposes the following routes:

* `/` : the default rails route
* `/metrics`: this is where the scaling metrics are exposed for Prometheus to scrape
* `/sidekiq`: the sidekiq dashbaord
* `/add-requests-in-queue` : a route that will just make the request sleep for a random number of seconds. 


The route `/add-requests-in-queue` tries to simulate a request that takes too much time to complete. Having a number of such simultaneusly requests will end up choking the passenger web server. 

In order to avoid requests queueing, we need to enable `Custom EYK HPA` so that more web pods will be started once a specific metric reaches a limit. In our case we have used the metric `passenger_workers` that is the number of passenger workers reported via `passenger-status`. Specifically we use the **average** number of `passenger_workers` reported across all our web pods.

One issue with the above approach is that the `custom metrics` is just a route in our application. Prometheus will scrape that route in order to obtain the desired metric and then signal the HPA to take action. In cases of high traffic spikes the requests to the `/metric` will be also queued, leading to no scaling.

In order to avoid that case we have modified the nginx template that passenger uses adding a route to `/metrics` on the nginx level. This route is served **not** by our application but by a minimal rack application. The rack application will just call the `passenger-status` command, scrape its output and display the metrics in order for Prometheus to read them. This way, even if passenger is queueing the requests, we can be assured that the `/metrics` route will be served and that HPA will scale the web pods accordingly.

Apart from web pods, we also have the sidekiq ones. Adding more jobs to the queue will increase the `sidekiq_busy_threads` metric, leading to scaling up the sidekiq pods too.

### How to see it in action

Deploy the application on EYK and get its URL via the command:

```
eyk info --app=<application's_name_here> | grep url: | awk '{print $2}'
```

Make the web pods scale up via using a v5 stack instance, issuing the following command in order to create heavy traffic:

```
ab -n 10000 -c 300 <the_URL_you_got_from_the_above_command>/add-requests-in-queue
```

Make the sidekiq pods scale up, issuing the following commands (any of them) in order to add background tasks to the queue:

```
eyk run "ECHO_JOB_COUNT=100 bundle exec rake echo:generate" --app=<application's_name_here>
eyk run "COMPLEX_JOB_COUNT=150 bundle exec rake complex:generate" --app=<application's_name_here>
eyk run "MEMCRASHER_JOB_COUNT=2 bundle exec rake memcrash:generate" --app=<application's_name_here>
eyk run "CPUCRASHER_JOB_COUNT=2 bundle exec rake cpucrash:generate" --app=<application's_name_here>
```

By visiting the URL `/metrics` endpoint you will see the passenger workers and sidekiq queue. Even if there are requests queued up, the `/metrics` request is served due to it being processed not by passenger but from the rack application. By issuing `eyk ps:list -app=<application's_name_here>` you may see the web pods scaling.

