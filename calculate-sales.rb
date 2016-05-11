require 'csv'
require './branch.rb'
require './commodity.rb'

def main
  return puts("支店定義ファイルが存在しません") unless File.exist?("#{ARGV[0]}/branch.lst")
  unless branches = load("branch.lst", "^\\d{3}$", Branch)
    return puts("支店定義ファイルのフォーマットが不正です")
  end
  return puts("商品定義ファイルが存在しません") unless File.exist?("#{ARGV[0]}/commodity.lst")
  unless commodities = load("commodity.lst", "^\\w{8}$", Commodity)
    return puts("商品定義ファイルのフォーマットが不正です")
  end

  sales_files = Dir.glob "*.rcd"
  return puts("売上ファイル名が連番になっていません") if sales_files.size != sales_files.last.to_i
  sales_files.each do |file|
    sales_table = CSV.table("#{ARGV[0]}/#{file}", {headers: ["header"], converters: :date})
    return puts("#{file}のフォーマットが不正です") if sales_table.size != 3
    return puts("#{file}の支店コードが不正です") unless calculate!(sales_table[:header][0], sales_table, branches)
    return puts("合計金額が10桁を超えました") if branches[sales_table[:header][0]].price.to_s.length > 10
    return puts("#{file}の商品コードが不正です") unless calculate!(sales_table[:header][1], sales_table, commodities)
    return puts("合計金額が10桁を超えました") if commodities[sales_table[:header][1]].price.to_s.length > 10
  end
  output("branch.out", branches)
  output("commodity.out", commodities)
end

def load(file_name, regex, klass)
  hash = {}
  CSV.foreach("#{ARGV[0]}/#{file_name}", {col_sep: "\n"}) do |row|
    formats = row[0].split(",")
    return nil if formats[0] !~ /#{regex}/
    hash.store(formats[0], (klass.new formats[0], formats[1], 0))
  end
  hash
end

def calculate!(code, sales_table, hash)
  return nil if hash[code].nil?
  hash[code].price += sales_table[:header][2].to_i
end

def output(file_name, hash)
  hash = hash.sort {|(k1, v1), (k2, v2)| v2.price <=> v1.price }
  File.open("#{ARGV[0]}/#{file_name}", 'w') {|fh| hash.each {|k, v| fh.write(v.to_csv)}}
end

main
