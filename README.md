# fluent-plugin-obsolete-plugins

[![Build Status](https://travis-ci.org/okkez/fluent-plugin-obsolete-plugins.svg?branch=master)](https://travis-ci.org/okkez/fluent-plugin-obsolete-plugins)

[Fluentd](http://fluentd.org/) filter plugin to warn obsolete plugins if detect on boot.

This plugin does not modify incoming records.

## Installation

### RubyGems

```
$ gem install fluent-plugin-obsolete-plugins
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-obsolete-plugins"
```

And then execute:

```
$ bundle
```

## Configuration

### plugins_json (string) (optional)

Path to `plugins.json`.

Default value: `https://raw.githubusercontent.com/fluent/fluentd-website/master/scripts/plugins.json`.


### Deprecated: obsolete_plugins_yml (string) (optional)

Path to `obsolete-plugins.yml`. This parameter is deprecated. Please use `plugins_json` parameter instead.

Default value: `nil`

### raise_error (bool) (optional)

Raise error if obsolete plugins are detected

Default value: `false`.

## Copyright

* Copyright(c) 2017- okkez
* License
  * Apache License, Version 2.0
