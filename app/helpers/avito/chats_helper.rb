module Avito
  module ChatsHelper
    def parse_date(raw_date)
      return if raw_date.nil?

      date = Time.zone.at raw_date
      current_date = Date.current
      return date.strftime('%H:%M') if current_date == date.to_date

      return date.strftime('%d %b') if current_date.year == date.year

      date.strftime('%d %b %y')
    end

    def formit_ad_title(item)
      return if item.nil?

      title = item['title'].presence
      return "#{title} — #{item['price_string'] || ''}" if title

      'Объявление временно недоступно'
    end

    def formit_msg(message)
      content = message['content']
      type    = message['type']
      return if content.nil?

      if type.match?(/text|system/)
        result = content['text']
        result += "\n#{message.dig('quote', 'content', 'text')}" if message['quote']
        result = "Неизвестный тип сообщения! #{type} #{message}" if type['system'] && content['text'].blank?
        result
      elsif type == 'image'
        img = content['image']['sizes']['640x480']
        str = <<~HTML
          <a data-fancybox="msg_img" data-src="#{content['image']['sizes']['1280x960']}" data-caption="1280x960" style="cursor:pointer;">
            <img src='#{img}' style='height: 200px;' />
          </a>
        HTML
        str.html_safe
      elsif type == 'link'
        result = content['link']['text']
        if content['link']['preview']
          result += "\n#{content.dig('link', 'preview',
                                     'url')}\n#{content.dig('link', 'preview', 'title')}"
        end
        result
      elsif content['voice']
        content['voice']['voice_id']
      elsif content['location']
        content['location']['text']
      elsif type == 'file'
        'ФАЙЛ'
      else
        "Неизвестный тип сообщения! #{type} #{message}"
      end
    end
  end
end
