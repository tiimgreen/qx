module ApplicationHelper
  include Pagy::Frontend

  def render_column_value(record, column)
    value = record.send(column)
    case value
    when ActiveSupport::TimeWithZone, Time, Date
      value.strftime("%Y-%m-%d %H:%M")
    when TrueClass, FalseClass
      value ? "\u2713" : "\u2717"
    when BigDecimal
      number_with_precision(value, precision: 2)
    else
      value.to_s
    end
  end

  def render_form_field(form, field, options = {})
    options ||= {}
    field_type = options[:type] || infer_field_type(form.object, field)

    case field_type
    when :text
      form.text_area field, class: "form-control", rows: 3
    when :date
      form.date_field field, class: "form-control"
    when :datetime
      form.datetime_local_field field, class: "form-control"
    when :boolean
      form.check_box field, class: "form-check-input"
    when :select
      form.select field,
                 options[:collection] || [],
                 options[:prompt] && { prompt: options[:prompt] },
                 { class: "form-select" }
    when :file
      form.file_field field, class: "form-control", direct_upload: true
    else
      form.text_field field, class: "form-control"
    end
  end

  def sort_indicator(column)
    return unless params[:sort] == column
    params[:direction] == "asc" ? "\u2191" : "\u2193"
  end

  def revision_status_label(isometry)
    return unless isometry.revision_number.present?

    css_class = isometry.revision_last? ? "bg-success" : "bg-danger"

    content_tag(:span, isometry.revision_number,
      class: "badge #{css_class} text-white")
  end

  def pressure_status_label(db_pressure, operating_pressure)
    return db_pressure if db_pressure.to_f > operating_pressure.to_f

    content_tag(:span, db_pressure, class: "badge bg-danger text-white")
  end

  def status_label(status)
    return if status.blank?

    css_class = case status.downcase
    when "ok", "accepted", "passed", "n/a", "yes", "ja", "e"
                "bg-success"
    when "not ok", "rejected", "failed", "on hold", "false", "no", "nein", "ne"
                "bg-danger"
    else
                "bg-warning"
    end

    content_tag(:span, status, class: "badge #{css_class} text-white")
  end

  def work_preparation_type_label(work_preparation)
    type = t("work_preparations.types.#{work_preparation.work_preparation_type}")
    css_class = work_preparation.completed ? "bg-success" : "bg-warning"

    content_tag(:span, type, class: "badge #{css_class} text-white")
  end

  def test_pack_type_label(test_pack)
    type = t("test_packs.types.#{test_pack.test_pack_type}")
    css_class = test_pack.completed ? "bg-success" : "bg-warning"

    content_tag(:span, type, class: "badge #{css_class} text-white")
  end

  def safe_percentage(numerator, denominator)
    return 0 if denominator.zero? || numerator.nil? || denominator.nil?
    (numerator.to_f * 100.0 / denominator.to_f).round
  end

  private

  def infer_field_type(object, field)
    return :select if field.to_s.end_with?("_id")

    case object.class.columns_hash[field.to_s]&.type
    when :text
      :text
    when :datetime
      :datetime
    when :date
      :date
    when :boolean
      :boolean
    else
      :string
    end
  end
end
