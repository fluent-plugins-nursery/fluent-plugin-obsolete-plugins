require "fluent/config/error"
require "open-uri"
require "yaml"
require "json"

class Fluent::Plugin::ObsoletePluginsUtils
  def self.obsolete_plugins_from_yaml(url)
    URI.open(url) do |io|
      YAML.safe_load(io.read)
    end
  end

  def self.obsolete_plugins_from_json(url)
    plugins = URI.open(url) do |io|
      # io.read causes Encoding::UndefinedConversionError with UTF-8 data when Ruby is started with "-Eascii-8bit:ascii-8bit".
      # It set the proper encoding to avoid the error.
      io.set_encoding("UTF-8", "UTF-8")
      JSON.parse(io.read)
    end
    plugins.select { |plugin| plugin["obsolete"] }.reduce({}) do |result, plugin|
      result[plugin["name"]] = plugin["note"]
      result
    end
  end

  def self.notify(logger, obsolete_plugins, raise_error: false)
    plugins = Gem.loaded_specs.keys & obsolete_plugins.keys
    plugins.each do |name|
      logger.warn("#{name} is obsolete: #{obsolete_plugins[name].chomp}")
    end
    if raise_error && !plugins.empty?
      raise Fluent::ConfigError, "Detected obsolete plugins"
    end
  end
end