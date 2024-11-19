module MaterialCertificateHelper
  def last_certificate_number(project_id)
    "Z#{MaterialCertificate.where(project_id: project_id).count}"
  end
end
