## Baseline 'dev'

```
Host 'MacBookPro' with 8 'arm64' processors with 16 GB memory, running:
Darwin Kernel Version 24.1.0: Thu Oct 10 21:05:14 PDT 2024; root:xnu-11215.41.3~2/RELEASE_ARM64_T8103
```
## EngineBenchmarks

### sim iteration

| Metric                        |      p0 |     p25 |     p50 |     p75 |     p90 |     p99 |    p100 | Samples |
|:------------------------------|--------:|--------:|--------:|--------:|--------:|--------:|--------:|--------:|
| Instructions (M) *            |    3143 |    3148 |    3150 |    3150 |    3150 |    3150 |    3150 |      15 |
| Malloc (total) *              |      22 |      22 |      22 |      22 |      22 |      22 |      22 |      15 |
| Memory (resident peak) (M)    |     203 |     203 |     203 |     203 |     203 |     203 |     203 |      15 |
| Throughput (# / s) (#)        |       3 |       3 |       3 |       3 |       3 |       3 |       3 |      15 |
| Time (total CPU) (ms) *       |     297 |     300 |     301 |     303 |     304 |     306 |     306 |      15 |
| Time (wall clock) (ms) *      |     297 |     300 |     301 |     303 |     303 |     306 |     306 |      15 |

