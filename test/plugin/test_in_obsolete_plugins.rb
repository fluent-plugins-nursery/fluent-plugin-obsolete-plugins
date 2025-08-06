require "helper"
require "fluent/test/driver/input"
require "fluent/plugin/in_obsolete_plugins"
require "fluent/plugin/obsolete_plugins_utils"

class ObsoletePluginsInputTest < Test::Unit::TestCase

  setup do
    Fluent::Test.setup
    @time = Time.now
    Timecop.freeze(@time)
  end

  teardown do
    Timecop.return
  end

  sub_test_case "plugins_json" do
    CONFIG_JSON = %[
      plugins_json #{fixture_path("plugins.json")}
    ]

    test "no obsolete plugins" do
      d = create_driver(CONFIG_JSON)
      d.run
      assert_equal([], d.events)
      assert_equal([], d.logs)
    end

    test "obsolete plugins" do
      stub(Gem).loaded_specs do
        {
          "fluent-plugin-tail-multiline" => nil,
          "fluent-plugin-hostname" => nil
        }
      end
      d = create_driver(CONFIG_JSON)
      d.run
      assert_equal([], d.events)
      expected_logs = [
        "#{@time} [warn]: fluent-plugin-tail-multiline is obsolete: Merged in in_tail in Fluentd v0.10.45. [fluent/fluentd#269](https://github.com/fluent/fluentd/issues/269)\n",
        "#{@time} [warn]: fluent-plugin-hostname is obsolete: Use [filter\\_record\\_transformer](http://docs.fluentd.org/v0.12/articles/filter_record_transformer) instead.\n"
      ]
      assert_equal(expected_logs, d.logs)
    end

    test "raise error when detect obsolete plugins" do
      stub(Gem).loaded_specs do
        {
          "fluent-plugin-tail-multiline" => nil,
          "fluent-plugin-hostname" => nil
        }
      end

      ex = assert_raise(Fluent::ConfigError) do
        create_driver(CONFIG_JSON + "raise_error yes")
      end
      assert_equal("Detected obsolete plugins", ex.message)
    end
  end

  sub_test_case "error handling" do
    test "invalid json" do
      d = create_driver("plugins_json #{fixture_path('invalid.json')}")

      expected_logs = [
        "#{@time} [info]: Failed to notify obsolete plugins error_class=JSON::ParserError error=\"expected ',' or '}' after object value, got: EOF at line 11 column 1\"\n",
      ]

      assert_equal(expected_logs, d.logs)
    end

    test "timeout with slow server" do
      server = create_slow_webserver(port: 12345)

      mock(Fluent::Plugin::ObsoletePluginsUtils).notify.never

      d = create_driver(%[
        plugins_json http://localhost:12345/plugins.json
        timeout 1
      ])

      sleep 2

      expected_logs = [
        "#{@time} [info]: Failed to notify obsolete plugins error_class=Timeout::Error error=\"execution expired\"\n",
      ]

      assert_equal(expected_logs, d.logs)
    ensure
      server.shutdown
    end

  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::ObsoletePluginsInput).configure(conf)
  end

  def create_slow_webserver(port: 12345)
    require "webrick"

    server = WEBrick::HTTPServer.new(Port: port)
    server.mount_proc '/' do |req, res|
      sleep 60

      res['Content-Type'] = 'application/json'
      res.body = File.read(fixture_path("plugins.json"))
    end

    server
  end
end
