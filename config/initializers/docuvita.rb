docuvita_creds = (Rails.application.credentials.docuvita || {})

DOCUVITA_CONFIG = {
  base_url: docuvita_creds[:base_url],
  session_guid: docuvita_creds[:session_guid],
  parent_object_id: docuvita_creds[:parent_object_id] || 4779, # default for test environment
  system_reference: docuvita_creds[:system_reference] || 1     # default for test environment
}

# only enforce presence checks when not explicitly skipping (e.g., during docker assets precompile)
unless ENV["SKIP_DOCUVITA_INIT"] == "1"
  raise "Docuvita base_url not configured" if DOCUVITA_CONFIG[:base_url].nil?
  raise "Docuvita session_guid not configured" if DOCUVITA_CONFIG[:session_guid].nil?
end

# ensure base_url doesn't end with a slash if present
if DOCUVITA_CONFIG[:base_url]
  DOCUVITA_CONFIG[:base_url] = DOCUVITA_CONFIG[:base_url].chomp("/")
end
