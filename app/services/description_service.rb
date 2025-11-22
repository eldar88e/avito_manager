class DescriptionService
  MATTRESS_SIZES = [2000, 1800, 1600, 1400, 1200, 1000, 900].freeze
  MATTRESS_LENGTH = 2000
  BED_SIZES = [[212, 140], [192, 140], [172, 140], [152, 130], [132, 120], [112, 120], [102, 120]].freeze
  LENGTH = 2140

  def initialize(description, replacements)
    @description  = description
    @replacements = replacements
  end

  def bed_sizes_str(value)
    str = "🛏 Другие размеры данной кровати:\n\n"
    count = 1
    BED_SIZES.each_with_index do |size, idx|
      next if size[0] == value

      str += "#{count}. Кровать: #{size[0]}0x#{LENGTH}x#{size[1]}0; Матрас: #{MATTRESS_SIZES[idx]}x#{MATTRESS_LENGTH};\n"
      count += 1
    end
    str += "\n**Размеры указанные в миллиметрах"
    str
  end

  def self.call(description, replacements)
    new(description, replacements).build_description
  end

  def build_description
    @replacements.each do |key, value|
      value        = bed_sizes_str(value) if key == :size && value.present?
      @description = @description.gsub("[#{key.to_s}]", value.to_s)
    end
    @description.squeeze(' ').strip
  end
end
