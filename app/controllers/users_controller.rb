class UsersController < ApplicationController
  require 'net/http'
  require 'uri'

  def new
    if current_user
      redirect_to new_post_path
    end
  end

  def create
    id_token = params[:idToken]
    channel_id = Settings.line_bot.liff_channel_id
    res = Net::HTTP.post_form(URI.parse('https://api.line.me/oauth2/v2.1/verify'), { 'id_token' => id_token, 'client_id' => channel_id })
    line_user_id = JSON.parse(res.body)['sub']
    name = JSON.parse(res.body)['name']
    user = User.find_by(line_user_id:)
    if user.nil?
      user = User.create(line_user_id:, name: )
      session[:user_id] = user.id
      render json: user
    elsif (session[:user_id] = user.id)
      render json: user
    end
  end
end
