require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'influxdb'
require 'json'

# From https://github.com/lusis/sensu_influxdb_handler
module Sensu::Extension
  class InfluxJson < Handler
    # The post_init hook is called after the main event loop has started
    # At this time EventMachine is available for interaction.
    def post_init
      server         = settings['influx']['host']
      port           = settings['influx']['port']
      use_ssl        = settings['influx']['ssl']
      username       = settings['influx']['username']
      password       = settings['influx']['password']
      database       = settings['influx']['database']
      time_precision = 's'

      @influxdb = InfluxDB::Client.new database,
                    host: server,
                    server: server,
                    port: port,
                    use_ssl: use_ssl,
                    username: username,
                    password: password,
                    time_precision: time_precision
    end

    # Must at a minimum define type and name. These are used by
    # Sensu during extension initialization.
    def definition
      {
        type: 'extension', # Always.
        name: 'influx_json', # Usually just class name lower case.
        mutator: 'ruby_hash'
      }
    end

    # Simple accessor for the extension's name. You could put a different
    # value here that is slightly more descriptive, or you could simply
    # refer to the definition name.
    def name
      definition[:name]
    end

    # A simple, brief description of the extension's function.
    def description
      'Outputs metrics to InfluxDB'
    end

    # run() is passed a copy of the event_data hash
    def run(event)
      begin
        # Process each line as an individual data point.
        # We expect lines to look like the following:
        #
        # {"metric": "series.name", "value": <value>, "time": <time>, "meta1": <v1>, "meta2", <v2>}
        #
        # The '.' characters in the series name will be converted to '_'.
        # The timestamp is unix timestamp (seconds).
        # The metadata key/value pairs are optional.
        event[:check][:output].each_line do |metric|
          @logger.debug("Parsing line: #{metric}")

          metric = metric.strip
          next if metric == ''

          metric = JSON.parse(metric)
          next unless metric.include?('metric') && metric.include?('value') && metric.include?('time')

          key = metric['metric'].gsub('.', '_')
          metric = metric.reject {|k| k == 'metric'}

          @logger.debug("Inserting key=#{key} metric=#{metric}")
          @influxdb.write_point(key, metric)
        end
      rescue => e
        @logger.error("InfluxDB: Error posting event: #{e.message}")
        @logger.error("InfluxDB: Backtrace:\n#{e.backtrace.join('\n')}")
        @logger.error("InfluxDB: #{event[:check][:output]}")
      end

      yield '', 0
    end

    # Called when Sensu begins to shutdown.
    def stop
      yield
    end
  end
end
