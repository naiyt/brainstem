require 'spec_helper'
require 'brainstem/inclusion_parser'

describe Brainstem::InclusionParser do
  describe '.parse' do
    it 'returns structured data from an inclusion string' do
      expect(Brainstem::InclusionParser.parse('')).to eq({})
      expect(Brainstem::InclusionParser.parse('tags')).to eq({ 'tags' => {} })
      expect(Brainstem::InclusionParser.parse('tags,people')).to eq({ 'tags' => {}, 'people' => {} })
      expect(Brainstem::InclusionParser.parse('tags,people()')).to eq({ 'tags' => {}, 'people' => {} })
      expect(Brainstem::InclusionParser.parse('tags,people(account)')).to eq({ 'tags' => {}, 'people' => { 'account' => {} } })
      expect(Brainstem::InclusionParser.parse('tags,people(account,projects)')).to eq({ 'tags' => {}, 'people' => { 'account' => {}, 'projects' => {} } })
      expect(Brainstem::InclusionParser.parse('tags,people(account,projects(posts,tags))')).to eq({ 'tags' => {}, 'people' => { 'account' => {}, 'projects' => { 'posts' => {}, 'tags' => {} } } })
      expect(Brainstem::InclusionParser.parse('tags(something),people(account,projects(posts,tags))')).to eq({ 'tags' => { 'something' => {} }, 'people' => { 'account' => {}, 'projects' => { 'posts' => {}, 'tags' => {} } } })
    end

    it 'errors on missing closing parens' do
      expect {
        Brainstem::InclusionParser.parse('tags,people(account,projects(posts,tags)')
      }.to raise_error(/Missing closing parenthesis/)

      expect {
        Brainstem::InclusionParser.parse('tags,people(account')
      }.to raise_error(/Missing closing parenthesis/)
    end

    it 'errors on too many closing parens' do
      expect {
        Brainstem::InclusionParser.parse('tags,people(account)),projects')
      }.to raise_error(/Too many closing parenthesis/)
    end

    it 'errors on missing token before opening parens' do
      expect {
        Brainstem::InclusionParser.parse('tags,(account)')
      }.to raise_error(/Missing token before parenthesis/)

      expect {
        Brainstem::InclusionParser.parse('(account)')
      }.to raise_error(/Missing token before parenthesis/)
    end
  end
end