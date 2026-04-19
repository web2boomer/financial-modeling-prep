require 'json'
require 'logger'
require 'time'
require 'faraday'

module FinancialModelingPrep
  class API
    HOST = "https://financialmodelingprep.com/api/"

    JSON_CONTENT_TYPE = 'application/json'

    RETRY_WAIT = 10
    MAX_RETRY = 6
    MAX_BACKOFF_429 = 120
    MAX_BACKOFF_5XX = 60
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 60

    def initialize(apikey = ENV['FINANCIAL_MODELING_PREP_API_KEY'])
      @apikey = apikey # fall back on ENV var if non passed in
    end

    # beginning of endpoints, note that there are inconsistencies with some endpoints using hyphens and some underscores. To make this more obvious, hypens are strings.

    def search(query:)
      request "v3/search", {query: query}
    end

    def search_ticker(query:)
      request "v3/search-ticker", {query: query}
    end

    def search_name(query:)
      request "v3/search-name", {query: query}
    end

    def profile(symbol:)
      request "v3/profile/#{symbol}"
    end

    def company_core_info(symbol:)
      request "v4/company-core-information", {symbol: symbol} # note v4 of API
    end

    def earnings_calendar(from:, to:)
      request "v3/earning_calendar", {from: from, to: to}
    end

    def earning_calendar_confirmed(from:, to:)
      request "v4/earning-calendar-confirmed", {from: from, to: to} # note v4 of API
    end

    def earning_call_transcript(symbol:, year: nil, quarter: nil)
      request "v3/earning_call_transcript/#{symbol}", {year: year, quarter: quarter}
    end

    def earning_call_dates(symbol:)
      request "v4/earning_call_transcript", {symbol: symbol} # note v4 of API
    end

    def batch_earning_call_transcript(symbol:, year: nil)
      request "v4/batch_earning_call_transcript/#{symbol}", {year: year} # note v4 of API
    end

    def press_releases(symbol:, page: 0)
      request "v3/press-releases/#{symbol}", {page: page}
    end

    def stock_news(tickers:, page: 0, limit: 50)
      request "v3/stock_news", {tickers: tickers, page: page, limit: limit}
    end

    def analyst_estimates(symbol:, period: nil, page: nil, limit: nil)
      request "v3/analyst-estimates/#{symbol}", {period: period, page: page, limit: limit}.compact
    end

    def price_target_consensus(symbol:)
      request "v4/price-target-consensus", {symbol: symbol}
    end

    def grades(symbol:, limit: nil)
      request "v3/grade/#{symbol}", {limit: limit}.compact
    end

    def insider_trading(symbol:, page: nil, limit: nil)
      request "v4/insider-trading", {symbol: symbol, page: page, limit: limit}.compact
    end

    def shares_float(symbol:)
      request "v4/shares_float", {symbol: symbol}
    end

    def ratios_ttm(symbol:)
      request "v3/ratios-ttm/#{symbol}"
    end

    def sec_filings(symbol: nil, type: nil, page: nil)
      if symbol
        request "v3/sec_filings/#{symbol}", {type: type, page: page}
      else
        request "v3/rss_feed", {page: page || 0}
      end
    end

    private

      def request(endpoint, args = {})
        retries = 0
        req_args = args.merge(apikey: @apikey)
        full_endpoint_url = nil

        begin
          full_endpoint_url = "#{HOST}#{endpoint}"
          response = connection.get(full_endpoint_url, req_args)

          case response.status
          when 401, 403
            raise AccessDenied, response.body

          when 200
            content_type = response.headers["content-type"] || response.headers["Content-Type"]
            unless content_type&.include?(JSON_CONTENT_TYPE)
              raise InvalidResponse, response.body
            end
            return JSON.parse(response.body)

          when 429, 500..599
            detail = parse_error_detail(response.body)
            msg = detail.empty? ? "#{response.status}" : "#{response.status} #{detail}"
            ra = parse_retry_after(response)
            raise ServiceUnavailable.new(msg, http_status: response.status, retry_after: ra)

          when 400..499
            raise Error, error_message_from_body(response.body, response.status)

          else
            raise Error, error_message_from_body(response.body, response.status)
          end
        rescue ServiceUnavailable => exception
          if retries < MAX_RETRY
            retries += 1
            wait = backoff_sleep(exception.http_status, exception.retry_after, retries)
            logger.info("Service unavailable for #{request_log_line(full_endpoint_url, req_args)} due to #{exception.message}, retrying (attempt #{retries} of #{MAX_RETRY}, sleeping #{wait.round(1)}s)...")
            sleep wait
            retry
          else
            logger.warn("Service unavailable for #{request_log_line(full_endpoint_url, req_args)} giving up after #{MAX_RETRY} attempts: #{exception.message}")
            raise exception
          end
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed => exception
          if retries < MAX_RETRY
            retries += 1
            wait = backoff_sleep(nil, nil, retries)
            logger.info("FMP connection error for #{request_log_line(full_endpoint_url, req_args)} (#{exception.class}: #{exception.message}), retrying (attempt #{retries} of #{MAX_RETRY}, sleeping #{wait.round(1)}s)...")
            sleep wait
            retry
          else
            logger.warn("FMP connection error for #{request_log_line(full_endpoint_url, req_args)} giving up after #{MAX_RETRY} attempts: #{exception.class}: #{exception.message}")
            raise exception
          end
        end
      end

      def connection
        @connection ||= Faraday.new do |f|
          f.options.open_timeout = OPEN_TIMEOUT
          f.options.timeout = READ_TIMEOUT
        end
      end

      def error_message_from_body(body, status)
        detail = parse_error_detail(body)
        detail.empty? ? "HTTP #{status}" : "#{status} #{detail}"
      end

      def parse_error_detail(body)
        return "" if body.nil?
        b = body.to_s
        return b.byteslice(0, 240) if b.strip.empty?
        json = JSON.parse(b)
        msg = json["Error Message"] || json["error"] || json["message"]
        s = msg&.to_s
        s = b.byteslice(0, 240) if s.nil? || s.empty?
        s.byteslice(0, 240)
      rescue JSON::ParserError
        b.byteslice(0, 240)
      end

      def parse_retry_after(response)
        raw = response.headers["retry-after"] || response.headers["Retry-After"]
        return nil if raw.nil? || raw.to_s.strip.empty?
        s = raw.to_s.strip
        if /\A\d+\z/.match?(s)
          s.to_i.clamp(1, 3600)
        else
          t = Time.httpdate(s)
          sec = (t - Time.now).to_i
          sec.clamp(1, 3600) if sec.positive?
        end
      rescue ArgumentError, TypeError
        nil
      end

      def backoff_sleep(http_status, retry_after, retries)
        jitter = rand * 2.0
        if retry_after
          return [retry_after.to_f, 3600].min + jitter
        end
        case http_status
        when 429
          exp = RETRY_WAIT * (2**(retries - 1))
          [exp, MAX_BACKOFF_429].min + jitter
        when 500..599
          exp = RETRY_WAIT * (2**(retries - 1))
          [exp, MAX_BACKOFF_5XX].min + jitter
        else
          RETRY_WAIT + jitter
        end
      end

      # URL + params for logs; apikey is never included.
      def request_log_line(full_endpoint_url, args)
        visible = args.reject { |k, _| k == :apikey || k == "apikey" }
        "#{full_endpoint_url} #{visible.inspect}"
      end

      def logger
        @logger ||= Logger.new(STDOUT)
      end
  end
end
