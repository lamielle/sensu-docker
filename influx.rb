require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'influxdb'

# From https://github.com/lusis/sensu_influxdb_handler
module Sensu::Extension
  class Influx < Handler
    # The post_init hook is called after the main event loop has started
    # At this time EventMachine is available for interaction.
    def post_init
      server         = settings['influx']['host']
      port           = settings['influx']['port']
      username       = settings['influx']['username']
      password       = settings['influx']['password']
      database       = settings['influx']['database']
      time_precision = 's'

      @influxdb = InfluxDB::Client.new database,
                    host: server,
                    server: server,
                    port: port,
                    username: username,
                    password: password,
                    time_precision: time_precision
    end

    # Must at a minimum define type and name. These are used by
    # Sensu during extension initialization.
    def definition
      {
        type: 'extension', # Always.
        name: 'influx', # Usually just class name lower case.
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
        # series.name value timestamp meta1=v1 meta2=v2
        #
        # The first component of the series name will be dropped.
        # The remaining '.' characters in the series name will be converted to '_'.
        # The timestamp is unix timestamp (seconds).
        # The metadata key/value pairs are optional.
        event[:check][:output].each_line do |metric|
          @logger.debug("Parsing line: #{metric}")
          fields = metric.split
          next unless fields.count >= 3

          key = fields[0].split('.', 2)[1]
          value = fields[1].to_f
          time = fields[2].to_i
          metadata = fields[3..fields.size]
          next unless key

          key.gsub!('.', '_')
          data = {
                   value: value,
                   time:  time,
                   host:  event[:client][:name],
                   ip:    event[:client][:address],
                 }

          metadata = Hash[fields[3..fields.size].map {|kv| kv.split('=')}]

          @logger.debug("Inserting data=#{data} metadata=#{metadata} merged=#{data.merge(metadata)}")
          @influxdb.write_point(key, data.merge(metadata))
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
