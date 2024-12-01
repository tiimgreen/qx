class WorkLocation < ApplicationRecord
  enum location_type: {
    workshop: "workshop",
    prefabrication: "prefabrication",
    construction_site: "construction_site"
  }

  validates :key, presence: true, uniqueness: true
  validates :location_type, presence: true,
                          inclusion: { in: location_types.keys }
end
