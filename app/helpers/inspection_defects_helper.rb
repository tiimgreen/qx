# app/helpers/inspection_defects_helper.rb
module InspectionDefectsHelper
  def severity_badge_class(severity)
    case severity.to_s.downcase
    when "critical"
      "bg-danger"
    when "major"
      "bg-warning text-dark"
    when "minor"
      "bg-info text-dark"
    else
      "bg-secondary"
    end
  end

  def severity_class(severity)
    case severity.to_s.downcase
    when "critical"
      "table-danger"
    when "major"
      "table-warning"
    when "minor"
      "table-info"
    else
      ""
    end
  end
end
