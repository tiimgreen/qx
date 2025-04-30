# app/models/docuvita_document.rb
class DocuvitaDocument < ApplicationRecord
  belongs_to :documentable, polymorphic: true

  validates :docuvita_object_id, presence: true
  validates :document_type, presence: true

  # Document types
  DOCUMENT_TYPES = %w[isometry_pdf rt_image vt_image pt_image on_hold_image qr_code].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }

  # Scope to find documents by type
  scope :of_type, ->(type) { where(document_type: type) }

  def download_content
    client = DocuvitaService::Client.new(
      DOCUVITA_CONFIG[:base_url],
      DOCUVITA_CONFIG[:session_guid]
    )
    client.get_document(docuvita_object_id)
  end
end
