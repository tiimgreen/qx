Sector modal - user must be added into user_sectors table. Also, we need to simulate qr link click.
  # Handle redirect to sector model sector redirections sector modal
  # to see that modal we need to use qr and user who is set in few sectors
  # user_sectors table. So if we go http://localhost:3000/en/qr/204
  # we will see modal with sectors and option what user want to do.

Access to Project Reports - user must be added into Project User table.

# scp deploy@188.245.217.88:/home/deploy/qx/db/production.sqlite3 /Volumes/CODE/qx/db/production.sqlite3

# Docuvita upload
# bundle exec rake 'docuvita:upload[/Users/nezirzahirovic/Downloads/welding.pdf,29,4779,My Rake Document,R,INV123,1]'

# Docuvita download
# bundle exec rake 'docuvita:download[6186,/Users/nezirzahirovic/Downloads/downloaded_document.pdf,1]'