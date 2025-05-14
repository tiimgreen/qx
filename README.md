Sector modal - user must be added into user_sectors table. Also, we need to simulate qr link click.
  # Handle redirect to sector model sector redirections sector modal
  # to see that modal we need to use qr and user who is set in few sectors
  # user_sectors table. So if we go http://localhost:3000/en/qr/204
  # we will see modal with sectors and option what user want to do.

Access to Project Reports - user must be added into Project User table.


# scp deploy@188.245.217.88:/home/deploy/qx/db/production.sqlite3 /Volumes/CODE/qx/db/production.sqlite3

# Docuvita upload
# bundle exec rake 'docuvita:upload[/Users/nezirzahirovic/Downloads/delivery-item.png,29,4779,My Rake Document,R,INV123,1]'

# bundle exec rake 'docuvita:upload[/Users/nezirzahirovic/Downloads/welding.pdf,29,4779,My Rake Document,R,INV123,1]'

# Docuvita download
# bundle exec rake 'docuvita:download[6186,/Users/nezirzahirovic/Downloads/downloaded_document.pdf,1]'

# Docuvita upload isometry pdfs (for a specific project)
# rails 'docuvita:upload_isometry_pdfs[26]'
# rails 'docuvita:upload_isometry_pdfs[17,5]'


# NEW

# Docuvita upload material certificates
# rails 'docuvita:upload_material_certificates_v2[2]'
# rails 'docuvita:upload_material_certificates_v2' 

# rails 'docuvita:upload_incoming_delivery_attachments'
# rails 'docuvita:upload_incoming_delivery_attachments[2]'

<!-- rails 'docuvita:upload_isometry_attachments[15,3]' -->
<!-- # Migrate all attachment types for all projects (default 10 isometries)
rails docuvita:upload_isometry_attachments

# Migrate specific number of isometries
rails docuvita:upload_isometry_attachments[50]

# Migrate for a specific project
rails docuvita:upload_isometry_attachments[50,123]  # Where 123 is the project_id

# Migrate only a specific attachment type
rails docuvita:upload_isometry_attachments[50,123,pdf]
rails docuvita:upload_isometry_attachments[50,123,rt_images]
rails docuvita:upload_isometry_attachments[50,123,vt_images]
rails docuvita:upload_isometry_attachments[50,123,pt_images]
rails docuvita:upload_isometry_attachments[50,123,on_hold_images] -->



<!-- # Migrate for all projects (default 10 images)
rails docuvita:upload_work_preparation_images

# Migrate specific number of images
rails docuvita:upload_work_preparation_images[50]

# Migrate for a specific project
rails docuvita:upload_work_preparation_images[50,123]  -->

<!-- 
# Migrate for all projects (default 10 images)
rails docuvita:upload_prefabrication_images

# Migrate specific number of images
rails docuvita:upload_prefabrication_images[50]

# Migrate for a specific project
rails docuvita:upload_prefabrication_images[50,123]  # Where 123 is the project_id -->

<!-- 
# Migrate for all projects (default 10 images)
rails docuvita:upload_pre_welding_images

# Migrate specific number of images
rails docuvita:upload_pre_welding_images[50]

# Migrate for a specific project
rails docuvita:upload_pre_welding_images[50,123]  # Where 123 is the project_id -->



<!-- # Migrate for all projects (default 10 images)
rails docuvita:upload_transport_images

# Migrate specific number of images
rails docuvita:upload_transport_images[50]

# Migrate for a specific project
rails docuvita:upload_transport_images[50,123]  # Where 123 is the project_id -->


<!-- # Migrate for all projects (default 10 images)
rails docuvita:upload_site_delivery_images

# Migrate specific number of images
rails docuvita:upload_site_delivery_images[50]

# Migrate for a specific project
rails docuvita:upload_site_delivery_images[50,123]  # Where 123 is the project_id -->



<!-- # Migrate for all projects (default 10 images)
rails docuvita:upload_site_assembly_images

# Migrate specific number of images
rails docuvita:upload_site_assembly_images[50]

# Migrate for a specific project
rails docuvita:upload_site_assembly_images[50,123]  # Where 123 is the project_id -->


<!-- # Migrate both image types for all projects (default 10 images)
rails docuvita:upload_on_site_images

# Migrate specific number of images
rails docuvita:upload_on_site_images[50]

# Migrate for a specific project
rails docuvita:upload_on_site_images[50,123]  # Where 123 is the project_id

# Migrate only on_hold_images
rails docuvita:upload_on_site_images[50,123,on_hold_images]

# Migrate only regular images
rails docuvita:upload_on_site_images[50,123,images] -->



<!-- # Migrate for all projects and all test pack types (default 10 images)
rails docuvita:upload_test_pack_images

# Migrate specific number of images
rails docuvita:upload_test_pack_images[50]

# Migrate for a specific project
rails docuvita:upload_test_pack_images[50,123]  # Where 123 is the project_id

# Migrate only pressure test packs
rails docuvita:upload_test_pack_images[50,123,pressure_test]

# Migrate only leak test packs
rails docuvita:upload_test_pack_images[50,123,leak_test] -->



<!-- # Migrate all image types for all projects (default 10 images)
rails docuvita:upload_final_inspection_images

# Migrate specific number of images
rails docuvita:upload_final_inspection_images[50]

# Migrate for a specific project
rails docuvita:upload_final_inspection_images[50,123]  # Where 123 is the project_id

# Migrate only a specific image type
rails docuvita:upload_final_inspection_images[50,123,on_hold_images]
rails docuvita:upload_final_inspection_images[50,123,visual_check_images]
rails docuvita:upload_final_inspection_images[50,123,vt2_check_images]
rails docuvita:upload_final_inspection_images[50,123,pt2_check_images]
rails docuvita:upload_final_inspection_images[50,123,rt_check_images] -->


<!-- # Migrate all image types for all projects (default 10 images)
rails docuvita:upload_delivery_item_images

# Migrate specific number of images
rails docuvita:upload_delivery_item_images[50]

# Migrate for a specific project
rails docuvita:upload_delivery_item_images[50,123]  # Where 123 is the project_id

# Migrate only a specific image type
rails docuvita:upload_delivery_item_images[50,123,quantity_check_images]
rails docuvita:upload_delivery_item_images[50,123,dimension_check_images]
rails docuvita:upload_delivery_item_images[50,123,visual_check_images]
rails docuvita:upload_delivery_item_images[50,123,vt2_check_images]
rails docuvita:upload_delivery_item_images[50,123,ra_check_images]
rails docuvita:upload_delivery_item_images[50,123,on_hold_images] -->




# NEED TO DO
# 2. Update current rake tasks to use docuvita
# 3. Create new rake tasks for uploading isometry rt vt pt on_hold images
# 4. Create new rake tasks for uploading on_hold images for all other sectors/models
# 5. Create new rake tasks for uploading other image files types on other models
# 6. Copy db 
# 7. Add keys into credentials for production


<!-- 
# Count delivery_notes attachments
delivery_notes_count = ActiveStorage::Attachment.where(
  record_type: "IncomingDelivery",
  name: "delivery_notes"
).count

# Count on_hold_images attachments
on_hold_images_count = ActiveStorage::Attachment.where(
  record_type: "IncomingDelivery",
  name: "on_hold_images"
).count

puts "Total delivery_notes attachments: #{delivery_notes_count}"
puts "Total on_hold_images attachments: #{on_hold_images_count}" -->



# document_types:
<!-- isometry
incoming_delivery
work_preparation
prefabrication
welding
final_inspection
transport
site_delivery
site_assembly
as_built
test_pack -->

# document_sub_types:
<!-- 
on_hold_image
visual_check_image
vt2_check_image
pt2_check_image
rt_check_image

quantity_check_image
dimension_check_image
ra_check_image

delivery_note

isometry
rt_image
vt_image
pt_image

material_certificate
on_site_image
check_spools_image -->