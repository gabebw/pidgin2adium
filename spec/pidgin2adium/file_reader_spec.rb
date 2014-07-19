require 'tempfile'

module FileReaderHelpers
  def no_op_cleaner
    Class.new do
      def self.clean(line)
        line
      end
    end
  end

  def dirty_cleaner
    Class.new do
      def self.clean(line)
        if line == "dirty"
          "clean"
        else
          line
        end
      end
    end
  end

  def temporary_file
    Tempfile.new('whatever').tap do |file|
      yield file
      file.flush
    end
  end
end

describe Pidgin2Adium::FileReader, 'with a nonexistent file' do
  include FileReaderHelpers

  it 'does not crash' do
    file_reader = Pidgin2Adium::FileReader.new('nonexistent', no_op_cleaner)
    expect { file_reader.read }.not_to raise_error
  end

  it 'has empty first_line' do
    file_reader = Pidgin2Adium::FileReader.new('nonexistent', no_op_cleaner)
    file_reader.read
    expect(file_reader.first_line).to eq('')
  end

  it 'has empty other_lines' do
    file_reader = Pidgin2Adium::FileReader.new('nonexistent', no_op_cleaner)
    file_reader.read
    expect(file_reader.other_lines).to eq([])
  end
end

describe Pidgin2Adium::FileReader, '#first_line' do
  include FileReaderHelpers

  it 'returns the first line' do
    file = temporary_file do |f|
      f.puts 'first'
      f.puts 'second'
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, no_op_cleaner)
    file_reader.read
    expect(file_reader.first_line).to eq('first')
  end

  it 'does not clean the first line' do
    file = temporary_file do |f|
      f.puts "dirty"
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, dirty_cleaner)
    file_reader.read
    expect(file_reader.first_line).to eq("dirty")
  end
end

describe Pidgin2Adium::FileReader, '#other_lines' do
  include FileReaderHelpers

  it 'grabs the other lines' do
    file = temporary_file do |f|
      f.puts 'first'
      f.puts 'second'
      f.puts 'third'
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, no_op_cleaner)
    file_reader.read
    expect(file_reader.other_lines).to eq(%w(second third))
  end

  it 'cleans the other lines' do
    file = temporary_file do |f|
      f.puts "first"
      f.puts "dirty"
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, dirty_cleaner)
    file_reader.read
    expect(file_reader.other_lines).to eq(%w(clean))
  end


  it 'removes empty lines from the other lines' do
    file = temporary_file do |f|
      f.puts "first"
      f.puts "before"
      f.puts
      f.puts "after"
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, no_op_cleaner)
    file_reader.read
    expect(file_reader.other_lines).to eq(%w(before after))
  end

  it 'removes all-whitespace lines from the other lines' do
    file = temporary_file do |f|
      f.puts "first"
      f.puts "before"
      f.puts "  "
      f.puts "after"
    end

    file_reader = Pidgin2Adium::FileReader.new(file.path, no_op_cleaner)
    file_reader.read
    expect(file_reader.other_lines).to eq(%w(before after))
  end
end
