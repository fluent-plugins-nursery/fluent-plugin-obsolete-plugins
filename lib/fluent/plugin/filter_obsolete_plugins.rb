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
require "fluent/plugin/obsolete_plugins_utils"

module Fluent
  module Plugin
    class ObsoletePluginsFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter("obsolete_plugins", self)

      PLUGINS_JSON_URL = "https://raw.githubusercontent.com/fluent/fluentd-website/master/scripts/plugins.json"

      desc "Path to obsolete-plugins.yml"
      config_param :obsolete_plugins_yml, :string, default: nil, deprecated: "use plugins_json parameter instead"
      desc "Path to plugins.json"
      config_param :plugins_json, :string, default: PLUGINS_JSON_URL
      desc "Timeout value to read data of obsolete plugins"
      config_param :timeout, :integer, default: 5
      desc "Raise error if obsolete plugins are detected"
      config_param :raise_error, :bool, default: false

      def configure(conf)
        super

        obsolete_plugins =
          if @obsolete_plugins_yml
            ObsoletePluginsUtils.obsolete_plugins_from_yaml(@obsolete_plugins_yml, timeout: @timeout)
          else
            ObsoletePluginsUtils.obsolete_plugins_from_json(@plugins_json, timeout: @timeout)
          end

        ObsoletePluginsUtils.notify(log, obsolete_plugins, raise_error: @raise_error)
      rescue Fluent::ConfigError
        raise
      rescue
        # ignore other exception
      end

      def filter(tag, time, record)
        record
      end
    end
  end
end
