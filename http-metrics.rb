#! /usr/bin/env ruby
#  encoding: UTF-8
#
# DESCRIPTION:
#   This plugin makes an HTTP request to the configured host/port/endpoint.
#   The unprocessed results are provided as output.  Thus, the output from
#   the request should be metric data in Graphite format.

# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux, Windows, BSD, Solaris, etc
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2012 Sonian, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'net/http'

if RUBY_VERSION < '1.9.0'
  require 'bigdecimal'

  class Float
    def round(val = 0)
      BigDecimal.new(to_s).round(val).to_f
    end
  end
end

class HttpStat < Sensu::Plugin::Metric::CLI::Graphite
  option :url,
         description: 'The full URL to query',
         short: '-u',
         long: '--url URL',
         required: true

  def run
    uri = URI(config[:url])
    res = Net::HTTP.get_response(uri)
    if res.is_a?(Net::HTTPSuccess)
      ok res.body
    else
      critical "Failed to query URL #{config[:url]}: #{res}"
    end
  end
end
