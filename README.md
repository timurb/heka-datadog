# Datadog encoder

Datadog encoder for Heka.

*Note:* experimental, use at your own risk.

## Usage

```
[DatadogEncoder]
type = "SandboxEncoder"
filename = "lua_encoders/datadog.lua"

  [DatadogEncoder.config]
  ts_from_message = true
  add_hostname_if_missing = true
  type_as_prefix = false
  tag_prefix = "tags."
  tag_list = "env adx"
  skip_fields = "Timestamp timestamp Metric metric Value value ExitStatus"

[debug_encoder]
type="RstEncoder"

[datadog]
type = "HttpOutput"
message_matcher = "Fields[your.metric.name] != NIL"
address = "https://app.datadoghq.com/api/v1/series?api_key=APIKEY"
encoder = "DatadogEncoder"
```
