# Prometheus Speedtest Exporter

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/cewood/prometheus-speedtest-exporter/main)](https://github.com/cewood/prometheus-speedtest-exporter/actions) [![Docker Image Version (latest by date)](https://img.shields.io/docker/v/cewood/prometheus-speedtest-exporter)](https://hub.docker.com/r/cewood/prometheus-speedtest-exporter/tags?page=1&ordering=last_updated) ![Docker Image Size (latest by date)](https://img.shields.io/docker/image-size/cewood/prometheus-speedtest-exporter)

This project is a Docker image that uses [script_exporter](https://github.com/ricoberger/script_exporter) to run a companion script ([speedtest-exporter.sh](speedtest-exporter.sh)), which collects speedtest data using the official [Ookla Speedtest CLI](https://www.speedtest.net/apps/cli) and then renders the results in a [Prometheus](https://prometheus.io/) compatible format. The [cewood/prometheus-speedtest-exporter](https://hub.docker.com/r/cewood/prometheus-speedtest-exporter) docker image is multi-arch image that supports the amd64, arm6, arm7, and arm64 platforms.


## Example metrics output

```
# HELP script_success Script exit status (0 = error, 1 = success).
# TYPE script_success gauge
script_success{} 1
# HELP script_duration_seconds Script execution time, in seconds.
# TYPE script_duration_seconds gauge
script_duration_seconds{} 30.603579
# HELP speedtest_latency_ms Latency
# TYPE speedtest_latency_ms gauge
speedtest_latency_ms{} 12.262
# HELP speedtest_jittter_ms Jitter
# TYPE speedtest_jittter_ms gauge
speedtest_jittter_ms{} 5.299
# HELP speedtest_download_bytes Download Speed
# TYPE speedtest_download_bytes gauge
speedtest_download_bytes{} 27090038
# HELP speedtest_download_bps Download Speed
# TYPE speedtest_download_bps gauge
speedtest_download_bps{} 216720304
# HELP speedtest_upload_bytes Upload Speed
# TYPE speedtest_upload_bytes gauge
speedtest_upload_bytes{} 3722160
# HELP speedtest_upload_bps Upload Speed
# TYPE speedtest_upload_bps gauge
speedtest_upload_bps{} 29777280
# HELP speedtest_downloadedbytes_bytes Downloaded Bytes
# TYPE speedtest_downloadedbytes_bytes gauge
speedtest_downloadedbytes_bytes{} 298992150
# HELP speedtest_uploadedbytes_bytes Uploaded Bytes
# TYPE speedtest_uploadedbytes_bytes gauge
speedtest_uploadedbytes_bytes{} 49291368
```


## Prometheus configuration

The script_exporter needs to be passed the script name as a parameter (script). Be sure to specify a suitably large `scrape_timeout` to allow the speedtest to safely complete. A word of warning, if your internet connection is metered then also consider the data usage that the speedtests will have and factor this into the `scrape_interval` that you decide on.

Basic config:

```yaml
scrape_configs:
  - job_name: 'speedtest'
    metrics_path: /probe
    params:
      script: [speedtest]
    static_configs:
      - targets:
        - 127.0.0.1:9469
    scrape_interval: 60m
    scrape_timeout: 90s
```

Advanced config:

[Speedtest-exporter.sh](speedtest-exporter.sh) supports specifying the server to run the speedtest against; a single argument passed to the script will be interpreted as a server-id, which is then passed to the speedtest-cli when it's invoked. This can be used in two ways; 1) to specify a list of server-id's which each should be speed tested, a common Prometheus pattern, and 2) to provide a single server-id to limit the speed tests to.

Below are example configurations of both of these approaches:

```yaml
scrape_configs:
  - job_name: 'speedtest multiple explicit servers'
    scrape_interval: 1m
    scrape_timeout: 30s
    metrics_path: /probe
    params:
      script: [speedtest]
      params: [target]
    static_configs:
      - targets:
        - 127.0.0.1:9469  # The script_exporter's hostname:port.
    static_configs:
      - targets:  # Each of these servers will be tested against
        - 30593
        - 17137
        - 20507
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - source_labels: [__param_target]
        target_label: target
      - target_label: __address__
        replacement: 127.0.0.1:9469  # The script_exporter's real hostname:port.

  - job_name: 'speedtest single explicit server'
    scrape_interval: 1m
    scrape_timeout: 30s
    metrics_path: /probe
    params:
      script: [speedtest]
      params: [30593]  # Only this single server will be tested
    static_configs:
      - targets:
        - 127.0.0.1:9469  # The script_exporter's hostname:port.

  - job_name: 'script_exporter metrics'
    metrics_path: /metrics
    static_configs:
      - targets:
        - 127.0.0.1:9469  # The script_exporter's metrics endpoint
```

In addition to supporting specifying the server-id to run the speedtest against, [speedtest-exporter.sh](speedtest-exporter.sh) supports displaying the server-id as a label in the resulting metrics. To enable this feature, [speedtest-exporter.sh](speedtest-exporter.sh) looks for an environment variable `SERVER_IDS`, which you can set to anything, and will result in the server-ids being rendered in the metrics as labels. You can see an example of this in the [docker-compose.yml](docker-compose.yml) which we use for testing, and a configuration for Kubernetes would be quite similar as well.


## Honourable mentions

This project was inspired by/is based upon the following projects:

 - https://github.com/billimek/prometheus-speedtest-exporter
 - https://github.com/h2xtreme/prometheus-speedtest-exporter
 - https://github.com/jeanralphaviles/prometheus_speedtest
 - https://github.com/pschmitt/docker-ookla-speedtest-cli
 - https://github.com/ricoberger/script_exporter
