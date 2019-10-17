# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibPtgBox::LibPtgBox do
  let(:sub_folder) { 'sub_folder' }
  let(:collection) { instance_double(LibPtgBox::Collection, 'collection', name: 'UMPEBC Metadata', catalog: catalog, selections: [selection]) }
  let(:catalog) { instance_double(LibPtgBox::Catalog, 'catalog', marc_folder: marc_folder) }
  let(:marc_folder) { object_double(LibPtgBox::Unmarshaller::MarcFolder.new(marc_ftp_folder), 'marc_folder', marc_files: marc_files, name: marc_ftp_folder.name) }
  let(:marc_ftp_folder) { instance_double(Ftp::Folder, 'marc_ftp_folder', name: 'folder') }
  let(:marc_files) { [] }
  let(:selection) {  instance_double(LibPtgBox::Selection, 'selection', name: 'name', year: 'year') }

  before do
    allow(LibPtgBox::Unmarshaller::RootFolder).to receive(:sub_folders).and_return([sub_folder])
    allow(LibPtgBox::Collection).to receive(:new).with(sub_folder).and_return(collection)
  end

  it '#initialize' do
    described_class.new
    expect(Dir.pwd).to eq(Rails.root.join('tmp', 'lib_ptg_box').to_s)
  end

  describe '#collections' do
    subject { described_class.new.collections }

    it { is_expected.to contain_exactly(collection) }
  end

  describe '#synchronize_catalog_marcs' do
    subject(:synchronize_catalog_marcs) { described_class.new.synchronize_catalog_marcs }

    let(:marc_files) { [marc_file] }
    let(:marc_file) { object_double(LibPtgBox::Unmarshaller::MarcFile.new(marc_ftp_file), 'marc_file', name: marc_ftp_file.name, updated: marc_ftp_file.updated, content: marc_ftp_file.content) }
    let(:marc_ftp_file) { instance_double(Ftp::File, 'marc_ftp_file', name: '0000000000000.mrc', updated: updated, content: content) }
    let(:updated) { Date.parse('1970-01-01') }
    let(:content) { 'content' }
    let(:string_io) { instance_double(StringIO, 'string_io') }
    let(:reader) { instance_double(MARC::Reader, 'reader') }
    let(:record) { instance_double(MARC::Record, 'record') }
    let(:marc) { instance_double(LibPtgBox::Unmarshaller::Marc, 'marc', doi: 'doi') }

    before do
      allow(MARC::Reader).to receive(:new).with(string_io, external_encoding: "UTF-8", validate_encoding: true).and_return(reader)
      allow(StringIO).to receive(:new).with(content).and_return(string_io)
      allow(reader).to receive(:each_raw).and_yield('raw')
      allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", validate_encoding: true).and_return(record)
      allow(LibPtgBox::Unmarshaller::Marc).to receive(:new).with(record).and_return(marc)
    end

    it 'new file' do
      expect(synchronize_catalog_marcs).to contain_exactly("NEW FILE CONTENT in folder > 0000000000000.mrc")
      expect(CatalogMarc.count).to eq(1)
    end

    it 'marc file deleted from box' do
      create(:catalog_marc)
      expect(CatalogMarc.count).to eq(1)
      expect(synchronize_catalog_marcs).to contain_exactly("FILE NOT FOUND  MyString > MyString deleting orphan record", "NEW FILE CONTENT in folder > 0000000000000.mrc")
      expect(CatalogMarc.count).to eq(1)
    end

    context 'when new file is empty' do
      before { allow(reader).to receive(:each_raw).and_return(nil) }

      it do
        expect(synchronize_catalog_marcs).to contain_exactly("NEW FILE CONTENT in folder > 0000000000000.mrc", "NO MARC RECORD in folder > 0000000000000.mrc record count = 0")
        expect(CatalogMarc.count).to eq(1)
      end
    end

    context 'when new file has multiple entries' do
      before { allow(reader).to receive(:each_raw).and_yield('raw').and_yield('raw') }

      it do
        expect(synchronize_catalog_marcs).to contain_exactly("NEW FILE CONTENT in folder > 0000000000000.mrc", "MULTIPLE MARC RECORDS in folder > 0000000000000.mrc record count = 2")
        expect(CatalogMarc.count).to eq(1)
      end
    end

    context 'when invalid UTF-8 encoding' do
      let(:upper) { instance_double(MARC::Record, 'upper', fields: [upper_field]) }
      let(:upper_field) { instance_double(MARC::DataField, 'upper_field', tag: 'Z') }
      let(:lower) { instance_double(MARC::Record, 'lower', fields: [lower_field]) }
      let(:lower_field) { instance_double(MARC::DataField, 'lower_field', tag: 'z') }

      before do
        allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", validate_encoding: true).and_raise(Encoding::InvalidByteSequenceError)
        allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", invalid: :replace).and_return(record)
        allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", invalid: :replace, replace: 'Z').and_return(upper)
        allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", invalid: :replace, replace: 'z').and_return(lower)
      end

      it do
        expect(synchronize_catalog_marcs).to contain_exactly("NEW FILE CONTENT in folder > 0000000000000.mrc", "ERROR Encoding::InvalidByteSequenceError reading folder > 0000000000000.mrc", "INVALID UTF-8 encoding for folder > 0000000000000.mrc https://doi.org/doi", "field Z #<Set: {\"\\\"lower_field\\\"]\", \"\\\"upper_field\\\"]\"}>")
        expect(CatalogMarc.count).to eq(1)
      end

      context 'when standard error' do
        before { allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", invalid: :replace).and_raise(StandardError) }

        it do
          expect(synchronize_catalog_marcs).to contain_exactly("ERROR Encoding::InvalidByteSequenceError reading folder > 0000000000000.mrc", "ERROR StandardError reading folder > 0000000000000.mrc", "NEW FILE CONTENT in folder > 0000000000000.mrc")
          expect(CatalogMarc.count).to eq(1)
        end
      end
    end

    context 'when standard error' do
      before { allow(MARC::Reader).to receive(:decode).with('raw', external_encoding: "UTF-8", validate_encoding: true).and_raise(StandardError) }

      it do
        expect(synchronize_catalog_marcs).to contain_exactly("NEW FILE CONTENT in folder > 0000000000000.mrc", "ERROR StandardError reading folder > 0000000000000.mrc")
        expect(CatalogMarc.count).to eq(1)
      end
    end
  end

  describe '#synchronize_umpbec_kbarts' do
    subject(:synchronize_umpbec_kbarts) { described_class.new.synchronize_umpbec_kbarts }

    it 'new kbart' do
      expect(synchronize_umpbec_kbarts).to be_empty
      expect(UmpebcKbart.count).to eq(1)
    end

    it 'kbart deleted from box' do
      create(:umpebc_kbart)
      expect(UmpebcKbart.count).to eq(1)
      expect(synchronize_umpbec_kbarts).to contain_exactly("FILE NOT FOUND for UMPEBC_1970 1970 deleting orphan record")
      expect(UmpebcKbart.count).to eq(1)
    end

    context 'when kbart record is verified' do
      let(:umpebc_kbart) { instance_double(UmpebcKbart, 'umpebc_kbart', verified: true) }
      let(:work) { instance_double(LibPtgBox::Work, 'work', marc?: true, marc: marc) }
      let(:marc) { instance_double(LibPtgBox::Unmarshaller::Marc, 'marc', doi: 'doi') }
      let(:catalog_marc) { instance_double(CatalogMarc, 'catalog_marc', doi: marc.doi, selected: selected) }
      let(:selected) { false }

      before do
        allow(UmpebcKbart).to receive(:find_or_create_by!).with(name: selection.name, year: selection.year).and_return(umpebc_kbart)
        allow(selection).to receive(:works).and_return([work])
        allow(CatalogMarc).to receive(:find_by).with(doi: marc.doi).and_return(catalog_marc)
        allow(umpebc_kbart).to receive(:verified=).with(false)
        allow(umpebc_kbart).to receive(:save!)
      end

      it 'when unselected' do
        expect(synchronize_umpbec_kbarts).to be_empty
        expect(umpebc_kbart).not_to have_received(:verified=).with(false)
        expect(umpebc_kbart).not_to have_received(:save!)
      end

      context 'when selected' do
        let(:selected) { true }

        it do
          expect(synchronize_umpbec_kbarts).to contain_exactly("At least one MARC record in #{selection.name} has been updated by Cataloging.")
          expect(umpebc_kbart).to have_received(:verified=).with(false)
          expect(umpebc_kbart).to have_received(:save!)
        end
      end
    end
  end
end
