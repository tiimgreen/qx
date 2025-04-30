DOCUVITA_CONFIG = {
  base_url: Rails.application.credentials.docuvita[:base_url],
  session_guid: Rails.application.credentials.docuvita[:session_guid],
  parent_object_id: Rails.application.credentials.docuvita[:parent_object_id] || 4779, # Default for test environment
  system_reference: Rails.application.credentials.docuvita[:system_reference] || 1     # Default for test environment
}

# Validate configuration
raise "Docuvita base_url not configured" if DOCUVITA_CONFIG[:base_url].nil?
raise "Docuvita session_guid not configured" if DOCUVITA_CONFIG[:session_guid].nil?

# Ensure base_url doesn't end with a slash
DOCUVITA_CONFIG[:base_url] = DOCUVITA_CONFIG[:base_url].chomp("/")
