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