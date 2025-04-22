require "helper"
require "fluent/plugin/filter_obsolete_plugins.rb"

class ObsoletePluginsFilterTest < Test::Unit::TestCase
  CONFIG = %[
    obsolete_plugins_yml #{fixture_path("obsolete-plugins.yml")}
  ]

  setup do
    Fluent::Test.setup
    $log = Fluent::Test::TestLogger.new
    @time = Time.now
    Timecop.freeze(@time)
  end

  teardown do
    Timecop.return
  end

  test "no obsolete plugins" do
    d = create_driver(CONFIG)
    d.run(default_tag: "test") do
      d.feed({ message: "This is test message." })
    end
    assert_equal([{ message: "This is test message." }], d.filtered_records)
    assert_equal([], d.logs)
  end

  test "obsolete plugins" do
    mock(Gem).loaded_specs do
      {
        "fluent-plugin-tail-multiline" => nil,
        "fluent-plugin-hostname" => nil
      }
    end
    d = create_driver(CONFIG)
    d.run(default_tag: "test") do
      d.feed({ message: "This is test message." })
    end
    assert_equal([{ message: "This is test message." }], d.filtered_records)
    expected_logs = [
      "#{@time} [warn]: fluent-plugin-tail-multiline is obsolete: Merged in in_tail in Fluentd v0.10.45. [fluent/fluentd#269](https://github.com/fluent/fluentd/issues/269)\n",
      "#{@time} [warn]: fluent-plugin-hostname is obsolete: Use [filter\\_record\\_transformer](http://docs.fluentd.org/v0.12/articles/filter_record_transformer) instead.\n"
    ]
    assert_equal(expected_logs, d.logs)
  end

  test "raise error when detect obsolete plugins" do
    mock(Gem).loaded_specs do
      {
        "fluent-plugin-tail-multiline" => nil,
        "fluent-plugin-hostname" => nil
      }
    end
    
    ex = assert_raise(Fluent::ConfigError) do
      create_driver(CONFIG + "raise_error yes")
    end
    assert_equal("Detected obsolete plugins", ex.message)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::ObsoletePluginsFilter).configure(conf)
  end
end
