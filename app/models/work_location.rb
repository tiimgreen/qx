class WorkLocation < ApplicationRecord
  enum location_type: {
    workshop: "workshop",
    prefab_facility: "prefab",
    construction_site: "site"
  }

  validates :key, presence: true, uniqueness: true
  validates :location_type, presence: true
end
