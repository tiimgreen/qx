class UserResourcePermission < ApplicationRecord
  belongs_to :user
  belongs_to :permission

  validates :resource_name, presence: true
  validates :user_id, uniqueness: { scope: [ :resource_name, :permission_id ] }

  RESOURCE_NAMES = [
    "IncomingDelivery",
    "DeliveryItem",
    "FinalInspection",
    "Isometry",
    "Prefabrication",
    "Project",
    "Transport",
    "MaterialCertificate",
    "WorkPreparation",
    "SiteDelivery",
    "SiteAssembly"
  ].freeze

  validates :resource_name, inclusion: { in: RESOURCE_NAMES }

  rails_admin do
    field :user do
      searchable [ :email, :first_name, :last_name ]
      pretty_value do
        bindings[:object].user&.email
      end
    end

    # Permission field
    field :permission do
      searchable [ :name ]
      pretty_value do
        bindings[:object].permission&.name
      end
    end

    # Resource name dropdown
    field :resource_name, :enum do
      enum {
        RESOURCE_NAMES.map { |name| [ name, name ] }.to_h
      }
    end
  end
end
