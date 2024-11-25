module SectorsHelper
  def sector_options
    Sector.all.map { |s| [ s.name, s.key ] }
  end
end
