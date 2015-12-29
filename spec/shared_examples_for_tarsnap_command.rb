shared_examples "TarsnapCommand" do

  describe '#list_archives' do
    it { is_expected.to respond_to :list_archives }
  end

  describe '#fsck' do
    it { is_expected.to respond_to :fsck }
  end

  describe '#delete' do
    it { is_expected.to respond_to :delete }
  end

end
