class Commodity
  attr_accessor :code, :name, :price

  def initialize(code, name, price)
    self.code = code
    self.name = name
    self.price = price
  end

  def to_csv
    "#{code},#{name},#{price}\n"
  end
end
