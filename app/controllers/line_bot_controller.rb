class LineBotController < ApplicationController
  protect_from_forgery :except => [:callback]
  def callback
    
    Linebot::Services::Callback.new(request: request).call
  end

end
