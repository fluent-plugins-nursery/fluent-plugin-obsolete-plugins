#
# Copyright 2017- okkez
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/filter"
require "open-uri"
require "yaml"

module Fluent
  module Plugin
    class ObsoletePluginsFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("obsolete_plugins", self)

      OBSOLETE_PLUGINS_URL = "https://raw.githubusercontent.com/fluent/fluentd-website/master/scripts/obsolete-plugins.yml"

      desc "Path to obsolete-plugins.yml"
      config_param :obsolete_plugins_yml, :string, default: OBSOLETE_PLUGINS_URL
      desc "Raise error if obsolete plugins are detected"
      config_param :raise_error, :bool, default: false

      def configure(conf)
        super

        @obsolete_plugins = open(@obsolete_plugins_yml) do |io|
          YAML.safe_load(io.read)
        end

        obsolete_plugins = Gem.loaded_specs.keys & @obsolete_plugins.keys
        obsolete_plugins.each do |name|
          $log.warn("#{name} is obsolete: #{@obsolete_plugins[name].chomp}")
        end
        if @raise_error && !obsolete_plugins.empty?
          raise Fluent::ConfigError, "Detected obsolete plugins"
        end
      end

      def filter(tag, time, record)
        record
      end
    end
  end
end
