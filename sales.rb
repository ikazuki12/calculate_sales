require 'csv'
BRANCH_LIST_FAIL_NAME = "branch.lst"
COMMODITY_LIST_FILE_NAME = "commodity.lst"
BRANCH_OUTPUT_FAIL_NAME = "branch.out"
COMMODITY_OUTPUT_FAIL_NAME = "commodity.out"
BRANCH_CODE_REGEX = "^\\d{3}$"
COMMODITY_CODE_REGEX = "^\\w{8}$"
class FileExistsError < StandardError; end
class FormatError < StandardError; end
class IncorrectSerialNumber < StandardError; end
class MoreThanTenDigits < StandardError; end
class ExceptionError < StandardError; end
def main
  message = Array.new
  branchTable  = nil
  begin
    branchTable = loadFile BRANCH_LIST_FAIL_NAME, BRANCH_CODE_REGEX
  rescue FileExistsError
    puts "支店定義ファイルが存在しません"
    return
  rescue FormatError
    puts "支店定義ファイルのフォーマットが不正です"
    return
  end
  commodityTable = nil
  begin
    commodityTable = loadFile COMMODITY_LIST_FILE_NAME, COMMODITY_CODE_REGEX
  rescue FileExistsError
    puts "商品定義ファイルが存在しません"
    return
  rescue FormatError
    puts "商品定義ファイルのフォーマットが不正です"
    return
  end
  Dir.glob ARGV[0] + "/\d{8}.rcd"
  Dir.chdir ARGV[0] + "/"
  salesfiles = Dir.glob "*.rcd"
  branchHash = {}
  commodityHash = {}
  begin
    serialNumberCheck salesfiles
    branchHash = totalSales salesfiles, branchHash, 0, branchTable, message, "支店"
    commodityHash = totalSales salesfiles, commodityHash, 1, commodityTable, message, "商品"
  rescue ExceptionError
    puts message[0]
    return
  rescue IncorrectSerialNumber
    puts "売上ファイル名が連番になっていません"
    return
  rescue MoreThanTenDigits
    puts "合計金額が10桁を超えました"
    return
  end
  branch = Hash[ branchHash.sort_by{ |_, v| -v } ]
  commodity = Hash[ commodityHash.sort_by{ |_, v| -v } ]
  resultOutPutFil BRANCH_OUTPUT_FAIL_NAME, branch, branchTable
  resultOutPutFil COMMODITY_OUTPUT_FAIL_NAME, commodity, commodityTable
  return
end

def loadFile fileName, regex
  if File.exist?(ARGV[0] + "/" + fileName)
    table = CSV.table(ARGV[0] + "/" + fileName, {
                :headers => ["code", "name"],converters: :date
              })
    table[:code].each do |format|
      if format !~ /#{regex}/
        raise FormatError
      else
        return table
      end
    end
  else
    raise FileExistsError
  end
end

def serialNumberCheck files
  files.each.with_index(1) do |file, i|
    fileBaseName = file.split(".")
    if fileBaseName[0].to_i - i != 0
      raise IncorrectSerialNumber
    end
  end
end

def totalSales files, hash, number, table, message, name
  files.each do |file|
    salesTable = CSV.table(ARGV[0] + "/" + file, {:headers => ["header"], converters: :date})
    if salesTable.size != 3
      message.push("#{file}のフォーマットが不正です")
      raise ExceptionError
    end
    if !table[:code].include?(salesTable[:header][number])
      message.push("#{file}の#{name}コードが不正です")
      raise ExceptionError
    end
    salesTable[:header].each.with_index do |row, i|
      if salesTable[:header][number] == table[:code][i] && hash[salesTable[:header][number]] == nil
        hash.store(salesTable[:header][number], salesTable[:header][2])
      elsif salesTable[:header][number] == table[:code][i] && hash[salesTable[:header][number]] != nil
        hash.store(salesTable[:header][number],
          hash[salesTable[:header][number]].to_i + salesTable[:header][2].to_i
          )
        else
          hash.store(table[:code][i],hash[table[:code][i]].to_i + 0)
        end
      end
    end
  hash.each do |key, value|
    if value.to_s.length > 10
      raise MoreThanTenDigits
    end
  end
  return hash
end

def resultOutPutFil file, hash, table
  File.open(ARGV[0] + "/" + file, 'w') do |fh|
    hash.each do |key, value|
      table.each do |row|
        if row[:code] == key
          str = "#{key},#{row[:name]},#{value}"
          fh.write(str + "\n")
        end
      end
    end
  end
end
puts main
