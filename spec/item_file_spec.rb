require 'dofus_file_format/item_file'
require 'dofus_file_format/i18n_file'

describe DofusFileFormat::ItemFile do
  describe 'initialized without i18n file' do
    let(:item_file) { DofusFileFormat::ItemFile.new file: File.open('test-data/Items.d2o') }

    it 'correctly fetches up an item at given offset' do
      item_file.object_at_offset(7)._criteria.should == 'null'
    end

    it 'correctly looks up an item by number' do
      item_file.item_numbered(40)._realWeight.should == 20
    end
  end

  describe 'initialized with i18n file' do
    let(:item_file_with_i18n) do
      DofusFileFormat::ItemFile.new \
        file: File.open("test-data/Items.d2o"),
        i18n_file: DofusFileFormat::I18nFile.new(file: File.open('test-data/i18n_en.d2i'))
    end

    it 'correctly shows item names' do
      item_file_with_i18n.item_numbered(400)._nameId.should == 'Barley'
    end

    it 'correctly finds an item by name' do
      item_file_with_i18n.item_named('Rampant Bearbarian Hammer')._level.should == 195
    end
  end
end

