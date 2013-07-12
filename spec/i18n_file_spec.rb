# coding: UTF-8
require 'dofus_file_format/i18n_file'
require 'nuggets/array/monotone'

describe DofusFileFormat::I18nFile do
  before :all do
    %w[en fr ja].each do |language|
      instance_variable_set :"@#{language}_file",
        DofusFileFormat::I18nFile.new(file: File.open("test-data/i18n_#{language}.d2i"))
    end
  end

  describe 'with English file' do
    it 'correctly fetches a message at given offset' do
      @en_file.message_at_offset(4).should ==
        'Trading in accounts or subscription'
    end

    it 'correctly finds message with given id' do
      @en_file.message_numbered(12).should ==
        'Your alignment is so weak that its very survival is threatened.'
    end

    it 'correctly finds message with given key' do
      @en_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        'Vulnerability start (local time)'
    end

    it 'correctly loads the sorted list of message numbers' do
      @en_file.sorted_message_numbers.last(3).map do |number|
        @en_file.message_numbered(number, true)
      end.should be_ascending
    end

    it 'correctly uses the sorted list to find the number for a message' do
      @en_file.number_for_message('Zoth Warrior Axe').should == 45761
    end
  end

  describe 'with French file' do
    it 'correctly fetches a message at given offset' do
      @fr_file.message_at_offset(4).should ==
        "Commerce de compte ou d'abonnement"
    end

    it 'correctly finds message with given id' do
      @fr_file.message_numbered(12).should ==
        'Votre alignement est si faible que sa survie est menacée.'
    end

    it 'correctly finds message with given key' do
      @fr_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        'Heure de vulnérabilité locale'
    end

    it 'correctly loads the sorted list of message numbers' do
      @fr_file.sorted_message_numbers.last(3).map do |number|
        @fr_file.message_numbered(number, true)
      end.should be_ascending
    end

    it 'correctly uses the sorted list to find the number for a message' do
      @fr_file.number_for_message('Hache du Guerrier Zoth').should == 45761
    end
  end

  describe 'with Japanese file' do
    it 'correctly fetches a message at given offset' do
      @ja_file.message_at_offset(4).should ==
        'アカウント売買'
    end

    it 'correctly finds message with given id' do
      @ja_file.message_numbered(12).should ==
        '同盟のレベルが弱すぎる。生き残れないかもしれない。'
    end

    it 'correctly finds message with given key' do
      @ja_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        '脆弱状態の時間(ローカル)'
    end

    it 'correctly loads the sorted list of message numbers' do
      @ja_file.sorted_message_numbers.last(3).map do |number|
        @ja_file.message_numbered(number, true)
      end.should be_ascending
    end

    it 'correctly uses the sorted list to find the number for a message' do
      @ja_file.number_for_message('ゾス戦士の斧').should == 45761
    end
  end
end
