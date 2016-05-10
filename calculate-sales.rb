require 'csv'
require './branch.rb'
require './commodity.rb'

def main
  return puts("支店定義ファイルが存在しません") if empty_file?("branch.lst")
  unless branches = lode_file("branch.lst", "^\\d{3}$", Branch)
    return puts("支店定義ファイルのフォーマットが不正です")
  end
  return puts("商品定義ファイルが存在しません") if empty_file?("commodity.lst")
  unless commodities = lode_file("commodity.lst", "^\\w{8}$", Commodity)
    return puts("商品定義ファイルのフォーマットが不正です")
  end
  
  sales_files = Dir.glob "*.rcd"
  return puts("売上ファイル名が連番になっていません") if sales_files.size != sales_files.last.to_i
  sales_files.each do |file|
    sales_table = CSV.table(ARGV[0] + "/" + file, {:headers => ["header"], converters: :date})
    return puts("#{file}のフォーマットが不正です") if sales_table.size != 3
    unless calculating!(sales_table[:header][0], sales_table, branches)
      return puts("#{file}の支店コードが不正です")
    end
    return puts("合計金額が10桁を超えました") unless exceed_ten?(branches, sales_table[:header][0])
    unless calculating!(sales_table[:header][1], sales_table, commodities)
      return puts("#{file}の商品コードが不正です")
    end
    return puts("合計金額が10桁を超えました") unless exceed_ten?(commodities, sales_table[:header][1])
  end
  output_file("branch.out", branches)
  output_file("commodity.out", commodities)
  return
end

def empty_file?(file_name)
  not File.exist?(ARGV[0] + "/" + file_name)
end

def lode_file(file_name, regex, klass)
  hash = {}
  CSV.foreach(ARGV[0] + "/" + file_name, {:col_sep => "\n"}) do |row|
    formats = row[0].split(",")
    return nil if formats[0] !~ /#{regex}/
    entity = klass.new formats[0], formats[1], 0
    hash.store(formats[0], entity)
  end
  hash
end

def calculating!(sales_table_code, sales_table, hash)
  return nil if hash[sales_table_code].nil?
  hash[sales_table_code].price += sales_table[:header][2].to_i
end

def exceed_ten?(hash, sales_table_code)
  not hash[sales_table_code].price.to_s.length > 10
end

def output_file(file_name, hash)
  hash = hash.sort {|(k1, v1), (k2, v2)| v2.price <=> v1.price }
  File.open(ARGV[0] + "/" + file_name, 'w') do |fh|
    hash.each do |key, value|
      str = "#{value.code},#{value.name},#{value.price}"
      fh.write(str + "\n")
    end
  end
end
puts main
