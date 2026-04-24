class MoneyService
  class << self
    def price_to_s(price, currency = '₽')
      int = price.to_i
      formatted = int.to_s.reverse.scan(/\d{1,3}/).join("\u00A0").reverse
      "#{formatted}\u00A0#{currency}"
    end
  end
end
