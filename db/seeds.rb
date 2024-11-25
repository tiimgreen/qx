# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Starting to seed sectors..."

# Clear existing records
Sector.delete_all

# Reset the sequence for SQLite3
ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='sectors'")

sectors_data = [
  { key: "project", position: 1 },
  { key: "isometric", position: 2 },
  { key: "incoming_delivery", position: 3 },
  { key: "work_preparation", position: 4 },
  { key: "prefabrication", position: 5 },
  { key: "welding", position: 6 },
  { key: "final_inspection", position: 7 },
  { key: "transport", position: 8 },
  { key: "site_delivery", position: 9 },
  { key: "assemblie", position: 10 },
  { key: "as_built", position: 11 },
  { key: "testing_and_pressur", position: 12 },
  { key: "documentation", position: 13 },
  { key: "material_certificate", position: 14 }
]

count = 0
sectors_data.each do |data|
  sector = Sector.find_or_initialize_by(key: data[:key])
  sector.position = data[:position]
  if sector.save!
    count += 1
    puts "Created/Updated sector: #{data[:key]}"
  end
end

puts "Successfully created/updated #{count} sectors"
