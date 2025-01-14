module Linebot
  module Services
    class Callback 

      def initialize(request:)
        @request = request

        $user_session = {} unless defined? $user_session
      end

      def call
         client = Client.new
         client.verify_request_signature(@request)
         events = client.get_events(@request)
         events.each do |event|
           case event
           when Line::Bot::Event::Follow
            line_user_id = event["source"]["userId"]
            current_user = User.create(line_user_id:) unless User.exists?(line_user_id:)
            current_user ||= User.find_by(line_user_id:)
           when Line::Bot::Event::Message
            line_user_id = event["source"]["userId"]
            current_user = User.create(line_user_id:) unless User.exists?(line_user_id:)
            current_user ||= User.find_by(line_user_id:)
            case event.type
            when Line::Bot::Event::MessageType::Text
              c = client.get
              user_id = event['source']['userId']
              user_info = {}
              if $user_session.key?(user_id)
                user_info = $user_session[user_id]
              else
                user_info = {state: 'initial'}
              end


              case user_info[:state]
              when "coupon_1"
                case event["message"]["text"]
                when "はい"
                  coupon = Coupon.create(serial_code: SecureRandom.uuid)
                  message = [
                    coupon_message(serial_code: coupon.serial_code) ,
                    {
                      type: "text",
                      text: "このコードを店員に見せてください"
                    }
                  ]
                  c.reply_message(event["replyToken"], message)
                  
                  $user_session.delete(user_id)
                when "いいえ"
                  message = {
                    type: "text",
                    text: "クーポン発行をキャンセルしました"
                  }
  
                  c.reply_message(event["replyToken"], message)
                  $user_session.delete(user_id)
                  
                end
              when "initial"
                case event["message"]["text"]
                when "在庫口コミ検索"
                  c.reply_message(event["replyToken"], stock_post_search_message)
                  $user_session[user_id] = {state: "search_1"}
                when "クーポン"
                  if Impression.exists?(created_at: Time.current.all_week, post_user_id: current_user.id)
                    impression_count = Impression.where(created_at: Time.current.all_week, post_user_id: current_user.id).count
                    border = 1
                    if impression_count >= border
                      unless Time.current.all_week.cover?(current_user.coupon_at)
                        c.reply_message(event["replyToken"], [{type:"text", text: "あなたの今週のインプレッション数は#{impression_count}です。クーポン発行には#{border}インプレッション必要です"},Y_N_message(), {type: "text", text: "クーポン発行できます！発行しますか？(商品購入時,レジ前で発行してください)"}])
                        $user_session[user_id] = {state: "coupon_1"}
                      else
                        c.reply_message(event["replyToken"], [{type:"text", text: "あなたの今週のインプレッション数は#{impression_count}です"},{type: "text", text: "今週は発行したためもうクーポンは発行できません！"}])
                      end
                    else
                      c.reply_message(event["replyToken"], [{type:"text", text: "あなたの今週のインプレッション数は#{impression_count}です。クーポン発行には#{border}インプレッション必要です"}])
                    end
                  else
                    c.reply_message(event["replyToken"], [{type:"text", text: "あなたはインプレッションされてません！クーポンを発行できません!"}])
                  end   
                  
                end

              when "search_1"
                message = {
                  type: "text",
                  text: "店舗名を入力してね！(例: あああああ店)"
                }
                case event["message"]["text"]
                when "ファミリーマート"
                  $user_session[user_id] = {state: "search_2", convenience_store_type: :familly_mart}
                  c.reply_message(event["replyToken"], message)
                when "セブンイレブン"
                  $user_session[user_id] = {state: "search_2", convenience_store_type: :seven_eleven}
                  c.reply_message(event["replyToken"], message)
                when "キャンセル"
                  $user_session.delete(user_id)
                  c.reply_message(event["replyToken"], [{type: "text", text: "検索をキャンセルしました！"}])
                else
                  c.reply_message(event["replyToken"], stock_post_search_message)
                end

              when "search_2"
                if (event["message"]["text"] == "キャンセル")
                  $user_session.delete(user_id)
                  c.reply_message(event["replyToken"], [{type: "text", text: "検索をキャンセルしました！"}])
                else

                  r = /(?:セブンイレブン|ファミリーマート|seveneleven|fammilymart)?(.+?)(?:店)?$/
                  match = event["message"]["text"].match(r)

                  store_name = match[1]
                  convenience_store_type = $user_session[user_id][:convenience_store_type]
                  posts = Post.where(convenience_store_type:, store_name:)
                  if (posts.presence)
                    
                    message = {
                      type: "text",
                      text: "#{match[1]}店だね！\n次は探したい商品名を入力してね！"
                    }
                    $user_session[user_id][:store_name] = "#{match[1]}"
                    $user_session[user_id][:state] = "search_3"
                    c.reply_message(event["replyToken"], message)
                  else
                    message = {
                      type: "text",
                      text: "この店舗に関する口コミは見つかりませんでした！もう一度入力をしてください。"
                    }
                    c.reply_message(event["replyToken"], message)
                  end

                  
                end
              when "search_3"

                if (event["message"]["text"] == "キャンセル" )
                  $user_session.delete(user_id)
                  c.reply_message(event["replyToken"], [{type: "text", text: "検索をキャンセルしました！"}])
                else
                  

                  product_name = event["message"]["text"]
                  store_name = $user_session[user_id][:store_name]
                  convenience_store_type = $user_session[user_id][:convenience_store_type]
                  posts = Post.where(convenience_store_type:, store_name:).includes(:products)

                  products = posts.flat_map do |post|
                    post.products.where(name: product_name)
                  end

                  if products.presence
                    message = {
                      type: "flex",
                      altText: "結果",
                      contents: {
                        type: "carousel",
                        contents: [

                        ] 
                      }
                    }
                    products.each do |product|
                      message[:contents][:contents] << product_bubble(content: product.content, created_at: product.created_at)
                      i = Impression.new(product_id: product.id, user_id: current_user.id, post_user_id: product.post.user.id)
                      i.save
                      
                    end
                    a = c.reply_message(event["replyToken"], [message, {type: "text", text: "#{convenience_store_type} #{store_name}店の#{product_name}の在庫口コミ一覧です！"}])
                    $user_session.delete(user_id)
                  else
                    message = {
                      type: "text",
                      text: "口コミはまだありません！もう一度商品名を入力してください！",
                    }

                    c.reply_message(event["replyToken"], message)
                  end
                end
              end
            end
          end
         end
      end

      def test_message
        JSON.parse(
          <<~JSON
          JSON
        )
      end

      def product_bubble(content:, created_at:)
        {
          "type": "bubble",
          "size": "nano",
          "body": {
            "type": "box",
            "layout": "vertical",
            "contents": [
              {
                "type": "box",
                "layout": "horizontal",
                "contents": [
                  {
                    "type": "text",
                    "text": "#{content}",
                    "size": "sm",
                    "wrap": true
                  }
                ],
                "flex": 1
              }
            ],
            "spacing": "md",
            "paddingAll": "12px",
            "margin": "lg"
          },
          "footer": {
            "type": "box",
            "layout": "vertical",
            "contents": [
              {
                "type": "text",
                "text":"#{created_at}" ,
                "size": "xs",
                "wrap": true
              }
            ],
            "spacing": "sm",
            "backgroundColor": "#EEEEEE"
          },
          "styles": {
            "footer": {
              "separator": false
            }
          }
        }
      end
        

      def stock_post_search_message
        {
          type: "flex",
          altText: "コンビニ選択画面",
          contents: {
            type: "bubble",
            body: {
              type: "box",
              layout: "vertical",
              spacing: "md",
              contents: [
                {
                  type: "button",
                  style: "primary",
                  action: {
                    type: "message",
                    label: "セブンイレブン",
                    text: "セブンイレブン",
                  },
                },
                {
                  type: "button",
                  style: "primary",
                  action: {
                    type: "message",
                    label: "ファミリーマート",
                    text: "ファミリーマート",
                  },
                },
                {
                  type: "button",
                  style: "secondary",
                  action: {
                    type: "message",
                    label: "キャンセル",
                    text: "キャンセル"
                  }
                }

              ]
              
            }
          }
        }
      end

      def Y_N_message
        {
          type: "flex",
          altText: "クーポン発行しますか",
          contents: {
            type: "bubble",
            body: {
              type: "box",
              layout: "vertical",
              spacing: "md",
              contents: [
                {
                  type: "button",
                  style: "primary",
                  action: {
                    type: "message",
                    label: "はい",
                    text: "はい",
                  },
                },
                {
                  type: "button",
                  style: "primary",
                  action: {
                    type: "message",
                    label: "いいえ",
                    text: "いいえ",
                  },
                },

              ]
              
            }
          }
        }
      end

      def coupon_message(serial_code:)
        {type: "flex",
         altText: "クーポン",
         contents:
          {
            "type": "bubble",
            "body": {
              "type": "box",
              "layout": "vertical",
              "contents": [
                {
                  "type": "text",
                  "text": "100円引きクーポン",
                  "weight": "bold",
                  "size": "xxl",
                  "margin": "md"
                },
                {
                  "type": "separator",
                  "margin": "xxl"
                },
                {
                  "type": "box",
                  "layout": "vertical",
                  "margin": "xxl",
                  "spacing": "sm",
                  "contents": [
                    {
                      "type": "box",
                      "layout": "horizontal",
                      "contents": [
                        {
                          "type": "text",
                          "text": "シリアルコード",
                          "size": "sm",
                          "color": "#111111",
                          "align": "center"
                        }
                      ]
                    },
                    {
                      "type": "separator"
                    },
                    {
                      "type": "box",
                      "layout": "vertical",
                      "contents": [
                        {
                          "type": "text",
                          "text": "#{serial_code}",
                          "align": "center",
                          "wrap": true
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            "styles": {
              "footer": {
                "separator": true
              }
            }
          }
        }
        
      end

    end
  end
end