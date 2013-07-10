# coding: UTF-8
require 'dofus_file_format/i18n_file'

describe DofusFileFormat::I18nFile do
  %w[en fr ja].each do |language|
    let(:"#{language}_file") do
      DofusFileFormat::I18nFile.read(File.read("test-data/i18n_#{language}.d2i"))
    end
  end

  describe 'with English file' do
    it 'correctly fetches a message at given offset' do
      en_file.message_at_offset(4).should ==
        'Trading in accounts or subscription'
    end

    it 'correctly finds message with given id' do
      en_file.message_numbered(12).should ==
        'Your alignment is so weak that its very survival is threatened.'
    end

    it 'correctly finds message with given key' do
      en_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        'Vulnerability start (local time)'
    end

  end

  describe 'with French file' do
    it 'correctly fetches a message at given offset' do
      fr_file.message_at_offset(4).should ==
        "Commerce de compte ou d'abonnement"
    end

    it 'correctly finds message with given id' do
      fr_file.message_numbered(12).should ==
        'Votre alignement est si faible que sa survie est menacée.'
    end

    it 'correctly finds message with given key' do
      fr_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        'Heure de vulnérabilité locale'
    end
  end

  describe 'with Japanese file' do
    it 'correctly fetches a message at given offset' do
      ja_file.message_at_offset(4).should ==
        'アカウント売買'
    end

    it 'correctly finds message with given id' do
      ja_file.message_numbered(12).should ==
        '同盟のレベルが弱すぎる。生き残れないかもしれない。'
    end

    it 'correctly finds message with given key' do
      ja_file.message_keyed('ui.prism.localVulnerabilityHour').should ==
        '脆弱状態の時間(ローカル)'
    end
  end
end
