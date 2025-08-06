require "fluent/plugin/input"
require "fluent/plugin/obsolete_plugins_utils"

module Fluent
  module Plugin
    class ObsoletePluginsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("obsolete_plugins", self)

      PLUGINS_JSON_URL = "https://raw.githubusercontent.com/fluent/fluentd-website/master/scripts/plugins.json"

      desc "Path to plugins.json"
      config_param :plugins_json, :string, default: PLUGINS_JSON_URL
      desc "Timeout value to read data of obsolete plugins"
      config_param :timeout, :integer, default: 5
      desc "Raise error if obsolete plugins are detected"
      config_param :raise_error, :bool, default: false

      def configure(conf)
        super

        obsolete_plugins = ObsoletePluginsUtils.obsolete_plugins_from_json(@plugins_json, timeout: @timeout)
        ObsoletePluginsUtils.notify(log, obsolete_plugins, raise_error: @raise_error)
      rescue Fluent::ConfigError
        raise
      rescue => e
        log.info("Failed to notify obsolete plugins", error: e)
      end
    end
  end
end
