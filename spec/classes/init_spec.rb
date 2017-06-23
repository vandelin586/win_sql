require 'spec_helper'
describe 'splunk' do
  context 'with default values for all parameters' do
    it { should contain_class('splunk') }
  end
end
