class DescriptionService
  MATTRESS_WIDTH = [200, 180, 160, 140, 120, 100, 90].freeze
  MATTRESS_LENGTH = 200
  BED_SIZES = [[212, 140], [192, 140], [172, 140], [152, 130], [132, 120], [112, 120], [102, 120]].freeze
  LENGTH = 214

  def initialize(description, replacements)
    @description  = description
    @replacements = replacements
  end

  def build_description
    @replacements.each do |key, value|
      value = bed_sizes_str(value) if key == :size && value.present?
      @description.gsub!("[#{key}]", value.to_s)
    end
    @description.squeeze(' ').strip
  end

  def self.call(description, replacements)
    new(description, replacements).build_description
  end

  private

  def bed_sizes_str(value)
    str   = "🛏 Другие размеры данной кровати:\n\n"
    count = 1
    BED_SIZES.each_with_index do |size, idx|
      next if size[0] == value

      mattress_size = "#{MATTRESS_WIDTH[idx]}×#{MATTRESS_LENGTH}"
      str += "#{count}. Кровать: #{size[0]}×#{LENGTH}×#{size[1]}; Матрас: #{mattress_size};\n"
      count += 1
    end
    str += "\n**Размеры указанные в сантиметрах"
    str
  end
end
