class MaterialCertificateItem < ApplicationRecord
  belongs_to :material_certificate
  belongs_to :delivery_item

  validates :material_certificate_id, uniqueness: { scope: :delivery_item_id }
end
