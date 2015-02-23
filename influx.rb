require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'influxdb'

# From https://github.com/lusis/sensu_influxdb_handler
module Sensu::Extension
  class Influx < Handler
    # The post_init hook is called after the main event loop has started
    # At this time EventMachine is available for interaction.
    def post_init
      server   = settings['influx']['host']
      port     = settings['influx']['port']
      username = settings['influx']['username']
      password = settings['influx']['password']
      database = settings['influx']['database']

      @influxdb = InfluxDB::Client.new database,
                    host: server,
                    server: server,
                    port: port,
                    username: username,
                    password: password
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
        event[:check][:output].each_line do |metric|
          @logger.debug("Parsing line: #{metric}")
          m = metric.split
          next unless m.count == 3
          key = m[0].split('.', 2)[1]
          next unless key
          key.gsub!('.', '_')
          value = m[1].to_f
          mydata = { host: event[:client][:name], value: value,
                     ip: event[:client][:address]
                   }
          @influxdb.write_point(key, mydata)
        end
      rescue => e
        @logger.error("InfluxDB: Error posting event - #{e.backtrace.to_s}")
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
