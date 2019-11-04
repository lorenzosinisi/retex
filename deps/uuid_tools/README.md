Elixir UUIDTools
===========

UUIDTools is a UUID generator and utilities for [Elixir](http://elixir-lang.org/). See [RFC 4122](http://www.ietf.org/rfc/rfc4122.txt).

### Installation

Releases are published through [hex.pm](https://hex.pm/packages/uuid_tools). Add as a dependency in your `mix.exs` file:

```elixir
defp deps do
  [ { :uuid_tools, "~> 0.1.0" } ]
end
```

Required at least OTP 21.3

### Why we need another UUID library?

I am of the idea that we need a UUID set of tools for our Elixir projects that is fast and complete (that is the reason for the name).
Even if now the library does not seem different than UUID or other erlang versions of it, the direction is to create a swiss knife of unique id generation
in our Elixir projects that is fast, complete and relaiable.


### Benchmark UUIDTools vs elixir_uuid


```elixir
	Benchmark suite executing with the following configuration:
	warmup: 2 s
	time: 10 s
	memory time: 1 s
	parallel: 1
	inputs: none specified
	Estimated total run time: 26 s

	Benchmarking UUID.uuid4/0...
	Benchmarking UUIDTools.uuid4/0...

	Name                        ips        average  deviation         median         99th %
	UUIDTools.uuid4/0      483.88 K        2.07 μs  ±1416.15%           2 μs           3 μs
	UUID.uuid4/0           326.39 K        3.06 μs   ±832.57%           3 μs           4 μs

	Comparison:
	UUIDTools.uuid4/0      483.88 K
	UUID.uuid4/0           326.39 K - 1.48x slower +1.00 μs

	Memory usage statistics:

	Name                      average  deviation         median         99th %
	UUIDTools.uuid4/0         0.27 KB     ±1.91%        0.27 KB        0.27 KB
	UUID.uuid4/0              1.58 KB     ±0.33%        1.58 KB        1.58 KB

	Comparison:
	UUIDTools.uuid4/0         0.27 KB
	UUID.uuid4/0              1.58 KB - 5.81x memory usage +1.30 KB
```


Copyright 2018-2019 Lorenzo Sinisi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


### UUID v1

Generated using a combination of time since the west adopted the gregorian calendar and the node id MAC address.

```elixir
iex> UUIDTools.uuid1()
"d2bd2f04-c4c8-11e9-8be2-f2189835db58"
```

### UUID v3

Generated using the MD5 hash of a name and either a namespace atom or an existing UUID. Valid namespace is `:md5`, nil or a binary

```elixir
iex> UUIDTools.uuid3(:md5, "google.com")
"fe4b24a0-9a38-3b32-84ca-ae0935462bc9"

iex> UUIDTools.uuid3("fe4b24a0-9a38-3b32-84ca-ae0935462bc9", "google.com")
"989a7ead-314e-31a1-9bb4-65033b275a99"
```

### UUID v4

Generated based on pseudo-random bytes.

```elixir
iex> UUIDTools.uuid4()
"3a569a7c-4d11-453f-82d8-f4fd328b2da0"
```

### UUID v5

Generated using the SHA1 hash of a name and either :sha1 atom or an existing UUID.

```elixir
iex> UUIDTools.uuid5(:sha1, "google.com")
"951fc05f-a587-5487-8201-edbf02bcb563"

iex> UUID.uuid5("951fc05f-a587-5487-8201-edbf02bcb563", "google.com")
"8a72bb90-08a6-584b-89c1-5416e4173cf9"
```

### Attribution

Some code ported from [avtobiff/erlang-uuid](https://github.com/avtobiff/erlang-uuid).
Most code ported from [zyro/elixir-uuid](https://github.com/zyro/elixir-uuid).

### License

```
Copyright 2018-2019 Lorenzo Sinisi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

```
