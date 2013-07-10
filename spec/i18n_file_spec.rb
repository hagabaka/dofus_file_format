# coding: UTF-8
require 'dofus/i18n_file'
require 'pry'

describe Dofus::I18n::File do
  %w[en fr ja].each do |language|
    let(:"#{language}_file") do
      Dofus::I18n::File.read(File.read("test-data/i18n_#{language}.d2i"))
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
  end
end
