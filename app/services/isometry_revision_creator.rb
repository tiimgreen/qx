class IsometryRevisionCreator
  def initialize(isometry)
    @isometry = isometry
  end

  def create_revision
    ActiveRecord::Base.transaction do
      # Get all isometries from current revision
      current_isometries = Isometry.where(
        project_id: @isometry.project_id,
        line_id: @isometry.line_id,
        revision_number: @isometry.revision_number
      )

      # Mark old revisions as not latest
      Isometry.where(project_id: @isometry.project_id, line_id: @isometry.line_id)
              .update_all(revision_last: false)

      # Create new revisions for all pages
      new_isometries = current_isometries.map do |iso|
        new_iso = iso.dup
        new_iso.revision_number = iso.revision_number + 1
        new_iso.revision_last = true

        # Copy attachments except isometry documents
        copy_attachments(iso, new_iso)

        # Copy associated records
        copy_material_certificates(iso, new_iso)
        copy_weldings(iso, new_iso)

        new_iso.save!
        new_iso
      end

      # Return the first page of new revision
      new_isometries.find { |iso| iso.page_number == 1 }
    end
  end

  private

  def copy_attachments(from_iso, to_iso)
    %i[rt_image vt_image pt_image on_hold_image].each do |doc_type|
      from_iso.docuvita_documents.of_type(doc_type.to_s).each do |doc|
        DocuvitaDocument.create!(
          documentable: to_iso,
          document_type: doc.document_type,
          docuvita_object_id: doc.docuvita_object_id
        )
      end
    end
  end

  def copy_material_certificates(from_iso, to_iso)
    from_iso.material_certificates.each do |cert|
      to_iso.material_certificates << cert
    end
  end

  def copy_weldings(from_iso, to_iso)
    from_iso.weldings.each do |welding|
      new_welding = welding.dup
      new_welding.isometry = to_iso
      new_welding.save!
    end
  end
end
