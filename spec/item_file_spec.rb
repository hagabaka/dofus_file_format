require 'dofus_file_format/object_file'
require 'dofus_file_format/i18n_file'

describe DofusFileFormat::ObjectFile do
  describe 'initialized without i18n file' do
    before :all do
      @object_file = DofusFileFormat::ObjectFile.new file: File.open('test-data/Items.d2o')
    end

    it 'correctly fetches up an item at given offset' do
      @object_file.object_at_offset(7)._criteria.should == 'null'
    end

    it 'correctly looks up an item by number' do
      @object_file.object_numbered(40)._realWeight.should == 20
    end

    it "correctly parses an item's effects" do
      @object_file.object_numbered(6461)._possibleEffects.should be_any {|effect|
        effect._effectId == 111 && effect._diceNum == 1 && effect._diceSide == 0
      }
    end
  end

  describe 'initialized with i18n file' do
    before :all do
      @object_file_with_i18n = DofusFileFormat::ObjectFile.new \
        file: File.open("test-data/Items.d2o"),
        i18n_file: DofusFileFormat::I18nFile.new(file: File.open('test-data/i18n_en.d2i'))
    end

    it 'correctly shows item names' do
      @object_file_with_i18n.object_numbered(400)._nameId.should == 'Barley'
    end

    it 'correctly finds an item by name' do
      @object_file_with_i18n.object_named('Rampant Bearbarian Hammer')._level.should == 195
    end
  end
end

