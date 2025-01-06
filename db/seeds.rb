# # This file should ensure the existence of records required to run the application in every environment (production,
# # development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# # The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
# #
# # Example:
# #
# #   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
# #     MovieGenre.find_or_create_by!(name: genre_name)
# #   end

# # This file should ensure the existence of records required to run the application in every environment (production,
# # development, test). The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Admin.create!(email: "nezir.zahirovic@gmail.com", password: "kiGA5#iyFc8$e8&bX", password_confirmation: "kiGA5#iyFc8$e8&bX", name: "Nezir Zahirovic")
# Admin.create!(email: "iztok.goetsch@qualinox.ch", password: "657$G9BnhQmQBs8hX", password_confirmation: "657$G9BnhQmQBs8hX", name: "Iztok Goetsch")
# Admin.create!(email: "adnan.kovacevic@qualinox.ch", password: "fGK&&9FKG9KCGhzhX", password_confirmation: "fGK&&9FKG9KCGhzhX", name: "Adnan Kovacevic")
# puts "added admins"

# User.create!(
#   email: "nezir@qx.com",
#   password: "123123123",
#   password_confirmation: "123123123",
#   first_name: "Nezir",
#   last_name: "Zahirovic",
#   phone: "12345678",
#   address: "Sample Address 1",
#   city: "Sample City"
# )
# User.create!(
#   email: "iztok@qx.com",
#   password: "123123123",
#   password_confirmation: "123123123",
#   first_name: "Iztok",
#   last_name: "Goetsch",
#   phone: "12345678",
#   address: "Sample Address 2",
#   city: "Sample City"
# )
# User.create!(
#   email: "adnan@qx.com",
#   password: "123123123",
#   password_confirmation: "123123123",
#   first_name: "Adnan",
#   last_name: "Kovacevic",
#   phone: "12345678",
#   address: "Sample Address 3",
#   city: "Sample City"
# )
# puts "added users"

# # Create Work Locations
# puts "Creating work locations..."
# [ "workshop", "prefabrication", "construction_site" ].each do |location_type|
#   WorkLocation.find_or_create_by!(key: location_type, location_type: location_type)
# end
# puts "added work locations"

# puts "Starting to seed sectors..."

# # Clear existing records
# Sector.delete_all

# # Reset the sequence for SQLite3
# ActiveRecord::Base.connection.execute("DELETE FROM sqlite_sequence WHERE name='sectors'")

# sectors_data = [
#   { key: "project", position: 1 },
#   { key: "isometric", position: 2 },
#   { key: "incoming_delivery", position: 3 },
#   { key: "work_preparation", position: 4 },
#   { key: "prefabrication", position: 5 },
#   { key: "welding", position: 6 },
#   { key: "final_inspection", position: 7 },
#   { key: "transport", position: 8 },
#   { key: "site_delivery", position: 9 },
#   { key: "site_assembly", position: 10 },
#   { key: "on_site", position: 11 },
#   { key: "test_pack", position: 12 },
#   { key: "material_certificate", position: 13 }
#   { key: "site_welding", position: 14}
# ]

# count = 0
# sectors_data.each do |data|
#   sector = Sector.find_or_initialize_by(key: data[:key])
#   sector.position = data[:position]
#   if sector.save!
#     count += 1
#     puts "Created/Updated sector: #{data[:key]}"
#   end
# end

# puts "Successfully created/updated #{count} sectors"

# # Create Permissions
# puts "Creating permissions..."
# [ "view", "create", "edit", "delete", "complete" ].each do |code|
#   Permission.find_or_create_by!(code: code, name: code.titleize)
# end

# # Create User Sectors
# puts "Creating user sectors..."
# user_sectors = [
#   { user_id: 1, sector_id: Sector.find_by(key: "incoming_delivery").id },
#   { user_id: 2, sector_id: Sector.find_by(key: "incoming_delivery").id },
#   { user_id: 3, sector_id: Sector.find_by(key: "incoming_delivery").id }
# ]

# user_sectors.each do |user_sector_attrs|
#   UserSector.find_or_create_by!(user_sector_attrs)
# end

# # Create User Resource Permissions
# puts "Creating user resource permissions..."
# resources = [ "IncomingDelivery", "DeliveryItem" ]
# permission_codes = [ "view", "edit", "create" ]

# # Get all permissions first
# permissions = Permission.where(code: permission_codes)

# [ 1, 2, 3 ].each do |user_id|
#   resources.each do |resource|
#     permissions.each do |permission|
#       UserResourcePermission.find_or_create_by!(
#         user_id: user_id,
#         resource_name: resource,
#         permission_id: permission.id
#       )
#     end
#   end
# end

# puts "Completed creating user sectors and permissions!"

# # Create Projects
# puts "Creating sample projects..."
# projects = [
#   { project_number: "P2024-001", name: "Sample Project 1", description: "First test project", project_manager: "John Doe", client_name: "Client A", user_id: 1 },
#   { project_number: "P2024-002", name: "Sample Project 2", description: "Second test project", project_manager: "Jane Smith", client_name: "Client B", user_id: 2 },
#   { project_number: "P2024-003", name: "Sample Project 3", description: "Third test project", project_manager: "Bob Johnson", client_name: "Client C", user_id: 3 }
# ]

# projects.each do |project_attrs|
#   Project.find_or_create_by!(project_attrs)
# end

# # Create Incoming Deliveries
# puts "Creating sample incoming deliveries..."
# project = Project.first
# work_location = WorkLocation.find_by(key: "workshop")

# incoming_deliveries = [
#   {
#     project: project,
#     delivery_date: Date.today,
#     order_number: "PO-2024-001",
#     supplier_name: "Supplier A",
#     notes: "First delivery",
#     delivery_note_number: "DN-001",
#     work_location: work_location,
#     user_id: 1
#   },
#   {
#     project: project,
#     delivery_date: Date.today - 1.day,
#     order_number: "PO-2024-002",
#     supplier_name: "Supplier B",
#     notes: "Second delivery",
#     delivery_note_number: "DN-002",
#     work_location: work_location,
#     user_id: 2
#   }
# ]

# incoming_deliveries.each do |delivery_attrs|
#   IncomingDelivery.find_or_create_by!(delivery_attrs)
# end

# # Create Delivery Items
# puts "Creating sample delivery items..."
# incoming_delivery = IncomingDelivery.first

# delivery_items = [
#   {
#     incoming_delivery: incoming_delivery,
#     tag_number: "TAG-001",
#     batch_number: "BATCH-001",
#     item_description: "Steel Pipe DN100",
#     delivery_note_position: "1",
#     actual_quantity: 10,
#     target_quantity: 10,
#     user_id: 3
#   },
#   {
#     incoming_delivery: incoming_delivery,
#     tag_number: "TAG-002",
#     batch_number: "BATCH-002",
#     item_description: "Steel Pipe DN150",
#     delivery_note_position: "2",
#     actual_quantity: 5,
#     target_quantity: 5,
#     user_id: 1
#   }
# ]

# delivery_items.each do |item_attrs|
#   DeliveryItem.find_or_create_by!(item_attrs)
# end

# (1..4).each_with_index do |permission, index|
# UserResourcePermission.create!(user_id: User.find(1).id, resource_name: "SiteAssembly", permission_id: index + 1)
# end
