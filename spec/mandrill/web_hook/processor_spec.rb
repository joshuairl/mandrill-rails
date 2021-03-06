require 'spec_helper'

describe Mandrill::WebHook::Processor do

  let(:params) { {} }
  let(:processor_class) { Mandrill::WebHook::Processor }
  let(:processor) { processor_class.new(params) }

  describe "#run!" do
    context "with inbound events" do
      before do
        processor_class.stub(:handle_inbound)
      end
      let(:event1) { { "event" => "inbound" } }
      let(:event2) { { "event" => "inbound" } }
      let(:params) { { "mandrill_events" => [event1,event2].to_json } }
      it "should pass event payload to the handler" do
        processor.should_receive(:handle_inbound).twice
        processor.run!
      end
    end
    context "with callback host" do
      shared_examples_for 'pass event payload to the handler' do

      end

      let(:callback_host) { callback_host_class.new }
      let(:processor) { processor_class.new(params,callback_host) }
      let(:event1) { { "event" => "inbound" } }
      let(:event2) { { "event" => "inbound" } }
      let(:params) { { "mandrill_events" => [event1,event2].to_json } }

      context "with handler method as public" do
        let(:callback_host_class) do
          Class.new do
            public

            def handle_inbound; end
          end
        end

        it "should pass event payload to the handler" do
          callback_host.should_receive(:handle_inbound).twice
          processor.run!
        end
      end
      context "with handler method as protected" do
        let(:callback_host_class) do
          Class.new do
            protected

            def handle_inbound; end
          end
        end

        it "should pass event payload to the handler" do
          callback_host.should_receive(:handle_inbound).twice
          processor.run!
        end
      end
      context "with handler method as private" do
        let(:callback_host_class) do
          Class.new do
            private

            def handle_inbound; end
          end
        end

        it "should pass event payload to the handler" do
          callback_host.should_receive(:handle_inbound).twice
          processor.run!
        end
      end
    end
    context "without handler method" do
      let(:event1) { { "event" => "inbound" } }
      let(:event2) { { "event" => "inbound" } }
      let(:params) { { "mandrill_events" => [event1,event2].to_json } }

      it "raises error on run!" do
        expect { processor.run! }
        .to raise_error(Mandrill::Rails::Errors::MissingEventHandler)
      end
    end
  end

  describe "#wrap_payload" do
    let(:raw_payload) { {} }
    subject { processor.wrap_payload(raw_payload) }
    its(:class) { should eql(Mandrill::WebHook::EventDecorator) }
  end

  describe "##authentic?" do
    let(:example_payload) { webhook_example_event('click_with_signature') }
    let(:expected_signature) { example_payload['headers']['X-Mandrill-Signature'] }
    let(:original_url) { example_payload['original_url'] }
    let(:webhook_key) { example_payload['private_key'] }
    let(:mandrill_webhook_keys) { [webhook_key] }
    let(:params) { example_payload['raw_params'] }
    subject { processor_class.authentic?(expected_signature, mandrill_webhook_keys, original_url, params) }
    context "when valid" do
      it { should be_true }
    end
    context "when no keys" do
      let(:mandrill_webhook_keys) { [] }
      it { should be_true }
    end
    context "when keys don't match" do
      let(:mandrill_webhook_keys) { ['bogative'] }
      it { should be_false }
    end
    context "when signature don't match" do
      let(:expected_signature) { 'bogative' }
      it { should be_false }
    end


  end

  describe "##generate_signature" do
    let(:example_payload) { webhook_example_event('click_with_signature') }
    let(:expected_signature) { example_payload['headers']['X-Mandrill-Signature'] }
    let(:original_url) { example_payload['original_url'] }
    let(:webhook_key) { example_payload['private_key'] }
    let(:params) { example_payload['raw_params'] }
    subject { processor_class.generate_signature(webhook_key, original_url, params) }
    it { should eql(expected_signature) }
  end

end
