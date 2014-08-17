require "spec_helper"

describe Pidgin2Adium::FileFinder do
  if on_travis_ci?
    before do
      FileUtils.rm_rf(expanded_directory)
    end
  else
    include FakeFS::SpecHelpers
  end

  before do
    FileUtils.mkdir_p(expanded_directory_with_username)
  end

  it "finds .html files" do
    create_file_with_extension("html")

    file_finder = Pidgin2Adium::FileFinder.new(unexpanded_directory)

    expect(file_finder.find).to eq ["#{expanded_directory_with_username}/in.html"]
  end

  it "finds .htm files" do
    create_file_with_extension("htm")

    file_finder = Pidgin2Adium::FileFinder.new(unexpanded_directory)

    expect(file_finder.find).to eq ["#{expanded_directory_with_username}/in.htm"]
  end

  it "finds .txt files" do
    create_file_with_extension("txt")

    file_finder = Pidgin2Adium::FileFinder.new(unexpanded_directory)

    expect(file_finder.find).to eq ["#{expanded_directory_with_username}/in.txt"]
  end

  it "does not find files with other extensions" do
    create_file_with_extension("bad")

    file_finder = Pidgin2Adium::FileFinder.new(unexpanded_directory)

    expect(file_finder.find).to eq []
  end

  def unexpanded_directory
    "~/input-logs/"
  end

  def expanded_directory_with_username
    File.join(expanded_directory, "gabebw")
  end

  def expanded_directory
    File.expand_path(unexpanded_directory)
  end

  def create_file_with_extension(extension)
    FileUtils.touch(File.join(expanded_directory_with_username, "in.#{extension}"))
  end
end
