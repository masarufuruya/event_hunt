require 'net/http'
require 'uri'
require 'json'
require 'date'

class MainController < ApplicationController
  def index
    # &ymd=20160326,20160316

    day = Date.today
    ymd = ''

    @today = Date.today.strftime("%Y年%m月%d日")
    lastDay = Date.today + 6
    @lastDay = lastDay.strftime("%Y年%m月%d日")

    for i in 0..6 do
      addDay = day + i
      if i > 0
        ymd = ymd +','+addDay.strftime("%Y%m%d")
      else
        ymd = addDay.strftime("%Y%m%d")
      end
    end

    if params[:category] != nil
      category = params[:category]
    end

    if category != nil
      requestUri = 'http://connpass.com/api/v1/event/?keyword='+category+',東京&count=100&order=2&ymd='+ymd
    else
      requestUri = 'http://connpass.com/api/v1/event/?keyword=swift,東京&count=100&order=2&ymd='+ymd
    end

    requestUri = URI.escape(requestUri)
    uri = URI.parse(requestUri)
    json = Net::HTTP.get(uri)
    #gem pry-rails入れるだけ
    result = JSON.parse(json)

    events = result['events']

    events.each{|event|
      event['started_at'] = DateTime.parse(event['started_at']).strftime('%Y年%m月%d日 %H:%M:%S')
    }
    @events = events
  end
end
