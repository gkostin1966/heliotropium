# frozen_string_literal: true

require_relative 'lib_ptg_box/marshaller'
require_relative 'lib_ptg_box/unmarshaller'

require_relative 'lib_ptg_box/work'
require_relative 'lib_ptg_box/selection'
require_relative 'lib_ptg_box/collection'
require_relative 'lib_ptg_box/lib_ptg_box'

module LibPtgBox
  BOX_LIB_PTG_BOX_PATH = '/Library PTG Box'

  # TMP_LIB_PTG_BOX_PATH = Rails.root.join('tmp', 'lib_ptg_box')
  # TMP_DOWNLOAD_PATH = Rails.root.join('tmp', 'lib_ptg_box', 'download')
  # TMP_UPLOAD_PATH = Rails.root.join('tmp', 'lib_ptg_box', 'upload')
  #
  # class << self
  #   def test
  #     LibPtgBox.new.collections.each do |collection|
  #       puts collection.name
  #       collection.selections.each do |selection|
  #         puts "--> " + selection.name + " " + selection.year + " " + selection.updated
  #         selection.works.each do |work|
  #           puts "----> #{work.doi}" unless work.marc?
  #         end
  #       end
  #     end
  #   end
  # end
end
