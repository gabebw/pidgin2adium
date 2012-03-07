shared_context "fake logger" do
  before do
    Pidgin2Adium.logger = stubbed_logger
  end

  after do
    Pidgin2Adium.logger = Pidgin2Adium::Logger.new
  end

  let(:stubbed_logger) do
    stub("logger", :warn => nil, :error => nil, :log => nil, :flush_warnings_and_errors => nil)
  end
end
