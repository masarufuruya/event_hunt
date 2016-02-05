require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'time'
require 'chronic'

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
    else
      category = 'swift'
    end

    requestUri = 'http://connpass.com/api/v1/event/?keyword='+category+',東京&count=100&order=2&ymd='+ymd

    requestUri = URI.escape(requestUri)
    uri = URI.parse(requestUri)
    json = Net::HTTP.get(uri)
    #gem pry-rails入れるだけ
    result = JSON.parse(json)

    events = result['events'].reverse

    events.each{|event|
      event['eventType'] = 'connpass'
    }

    doorkeeperEvents = getDoorKeeper(category, Date.today, Date.today + 6)

    doorkeeperEvents.each{|result|
      result['event'].each{|key, value|
        if key == 'starts_at'
          result['started_at'] = result['event']['starts_at']
        elsif key == 'ticket_limit'
          result['limit'] = result['event']['ticket_limit']
        elsif key == 'participants'
          result['accepted'] = result['event']['participants']
        elsif key == 'public_url'
          result['event_url'] = result['event']['public_url']
        else
          result[key] = result['event'][key]
        end
      }
      result['eventType'] = 'doorkeeper'
    }

    resultEvents = []
    events.each{|conpassEvent|
      doorkeeperEvents.each{|doorEvent|
        if conpassEvent['started_at'] < doorEvent['started_at']
          startStr = conpassEvent['started_at']
          startTime = Chronic.parse(startStr)
          if (startTime != nil)
            conpassEvent['started_at'] = startTime.strftime('%Y年%m月%d日 %H:%M:%S')
          end
          resultEvents = resultEvents + [conpassEvent]
        elsif conpassEvent['started_at'] > doorEvent['started_at']
          timeStartAt = Chronic.parse(doorEvent['started_at'])
          if (timeStartAt != nil)
            timeStartAt = timeStartAt + (60*540) #tokyo
            doorEvent['started_at'] = timeStartAt.strftime('%Y年%m月%d日 %H:%M:%S')
          end
          resultEvents = resultEvents + [doorEvent]
        end
      }
    }
    @events = resultEvents
  end

  def getDoorKeeper(keyword, sinceDate, untilDate)
    requestUri = "http://api.doorkeeper.jp/events/?q=#{keyword}&since=#{sinceDate}&until=#{untilDate}&sort=starts_at"
    requestUri = URI.escape(requestUri)
    uri = URI.parse(requestUri)
    json = Net::HTTP.get(uri)
    return JSON.parse(json)
  end

  def formatDate(dateStr)
    return DateTime.parse(dateStr).strftime('%Y年%m月%d日 %H:%M:%S')
  end

end
