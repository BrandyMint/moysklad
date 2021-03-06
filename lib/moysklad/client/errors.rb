class Moysklad::Client
  class Errors
    def self.build res
      body = res.body.force_encoding('utf-8')
      content_type = res.headers['content-type']

      if content_type.start_with? 'application/json'
        # ok
      elsif content_type.start_with? 'text/html'
        raise HtmlParsedError, body
      else
        raise UnknownError, body
      end

      # Encoding::UndefinedConversionError
      # "\xD0" from ASCII-8BIT to UTF-8
      begin
        body = JSON.parse body
        Moysklad.logger.debug "Moysklad::Client: #{res.status}: #{res.headers}, #{res.env.url.to_s}\n#{body}"
      rescue Encoding::UndefinedConversionError => err
        Moysklad.logger.error "#{err}"
      rescue JSON::ParserError => err
        Moysklad.logger.error "#{err}: #{res.headers}, body:#{body}"
        raise ParsingError, body
      end

      case res.status
      when 401
        raise UnauthorizedError.new body
      when 403
        raise ResourceForbidden.new body
      when 404
        raise NoResourceFound.new body
      when 405, 412
        raise MethodNotAllowedError.new body
      when 500
        raise InternalServerError.new body
      when 502
        raise BadGatewayError.new body
      else
        raise JsonParsedError.new body
      end
    end
  end
end

class Moysklad::Client
  class Error < StandardError
    attr_reader :message

    def initialize mess
      @message = mess
    end

    def to_s
      message.to_s.encode('utf-8')
      # <?xml version="1.0" encoding="UTF-8"?> <error> <uid>kiiiosk@wannabemoscow</uid> <moment>20150609112728449</moment> <message>������������ ���� ���������� �������� ������������.</message> </error>
    rescue Encoding::CompatibilityError
      message.to_s.force_encoding('cp1251').encode('utf-8')
    end
  end
  class ParsingError < Error; end

  class UnknownError < Error; end

  class NoResourceFound < Error; end

  class JsonParsedError < Error
    def initialize result
      super result.to_json
    end

    attr_reader :error
  end

  class HtmlParsedError < Error
    def initialize body
      @message = parse_title body
    end

    private

    def parse_title body
      Nokogiri::HTML(body).css('body').text
    rescue => err
      Moysklad.logger.debug "Moysklad::Client parse error #{err}: #{body}"
      body.force_encoding('utf-8')
    end
  end

  class MethodNotAllowedError < JsonParsedError
  end

  class UnauthorizedError < JsonParsedError
  end

  class ResourceForbidden < JsonParsedError
  end

  class ParsedError < Error
    def initialize result
      @status = result.status
      @result = result
      case result.headers['content-type']

      when /application\/xml/
        @error = Moysklad::Entities::Error.parse result.body
        @message = @error.message
      when /text\/html/
        doc = Nokogiri::HTML result.body
        @message = doc.css('body').css('h1').text
      else
        raise "Unknown content-type #{result.headers['content-type']} to parse error #{result.body}"
      end
    rescue => err
      @message = "error in init #{err}: #{result}"
    end

    attr_reader :error
  end


  class BadGatewayError < JsonParsedError; end
  class InternalServerError < JsonParsedError; end
end
