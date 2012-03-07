shared_context "fake logger" do
  before do
    @original_logger = Pidgin2Adium.logger
    Pidgin2Adium.logger = stubbed_logger
  end

  after do
    Pidgin2Adium.logger = @original_logger
  end

  let(:stubbed_logger) do
    stub("logger", :warn => nil, :error => nil, :log => nil, :flush_warnings_and_errors => nil)
  end
end
