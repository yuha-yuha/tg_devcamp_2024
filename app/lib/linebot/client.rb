module Linebot
  class Client
    def initialize
      @client ||= Line::Bot::Client.new do |config|
        config.channel_id = Settings.line_bot.channel_id
        config.channel_secret = Settings.line_bot.channel_secret
        config.channel_token = Settings.line_bot.channel_token
      end
    end

    def get
      @client
    end

    def verify_request_signature(request)
      signature = request.env['HTTP_X_LINE_SIGNAURE']
      unless @client.validate_signature(request.body.read, signature)
        return false
      else
        return true
      end
    end

    def get_events(request)
      @client.parse_events_from(request.body.read)
    end

    def send_reply_message(event, message)
      @client.reply_message(event['replyToken'], message)
    end

    
  end
end