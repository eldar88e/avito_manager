module Avito
  module AutoloadHelper
    TIME_SLOTS = [*0..23].map { |i| { id: i, name: "#{i}:00-#{i + 1}:00" } }.freeze
  end
end
