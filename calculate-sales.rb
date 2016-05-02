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
  Dir.glob ARGV[0] + "/\d{8}.rcd"
  Dir.chdir ARGV[0] + "/"
  sales_files = Dir.glob "*.rcd"
  return puts("売上ファイル名が連番になっていません") if sequence_check?(sales_files)
  return unless branches = calculating!(sales_files, branches, "支店", 0)
  return unless commodities = calculating!(sales_files, commodities, "商品", 1)
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

def sequence_check?(sales_files)
  sales_files.each_with_index do |file, i|
     return true if file.to_i % ( i + 1 ) != 0
  end
  false
end

def calculating!(sales_files, hash, name, number)
  sales_files.each do |file|
    sales_table = CSV.table(ARGV[0] + "/" + file, {:headers => ["header"], converters: :date})
    if sales_table.size != 3
      puts("#{file}のフォーマットが不正です")
      return nil
    end
    if hash[sales_table[:header][number]].nil?
      puts("#{file}の#{name}コードが不正です")
      return nil
    else
      hash[sales_table[:header][number]].price += sales_table[:header][2].to_i
    end
    if hash[sales_table[:header][number]].price.to_s.length > 10
      puts("合計金額が10桁を超えました")
      return nil
    end
  end
  hash
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
