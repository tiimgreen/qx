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

  def status_label(status)
    return if status.blank?

    css_class = case status.downcase
    when "ok", "accepted", "passed", "n/a", "yes", "ja"
                "bg-success"
    when "not ok", "rejected", "failed", "on hold", "false", "no", "nein"
                "bg-danger"
    else
                "bg-warning"
    end

    content_tag(:span, status, class: "badge #{css_class} text-white")
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
