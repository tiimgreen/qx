require "prawn"
require "prawn/templates"
require "prawn/table"

class WeldingPdfGenerator
  def initialize(isometry)
    @isometry = isometry
    @welds = isometry.weldings
  end

  def generate
    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: [ 30, 30, 30, 30 ]) do |pdf|
      # Set up repeating header for all pages
      pdf.repeat(:all) do
        pdf.bounding_box([ 0, pdf.bounds.top ], width: pdf.bounds.width, height: 80) do
          # Company logo on the left
          pdf.image "#{Rails.root}/app/assets/images/logo.png", width: 120, position: :left, vposition: :top

          pdf.text "<b>Isometrie / Isometric:</b> #{@isometry.line_id}", size: 11, inline_format: true
          pdf.text "<b>Projekt Nr. / Project No.:</b> #{@isometry.project.project_number}", size: 11, inline_format: true
          pdf.move_down 5
          pdf.text "Protokoll Schweissnaht / Weldlog", size: 14, style: :bold, align: :center
        end
      end

      # Start the content below the header
      pdf.bounding_box([ 0, pdf.bounds.top - 85 ], width: pdf.bounds.width, height: pdf.bounds.height - 85) do
        generate_table(pdf)
        generate_footer(pdf)
      end

      # Add page numbers - OUTSIDE of any repeat block
      pdf.number_pages "<page> von <total>",
                      at: [ pdf.bounds.right - 70, pdf.bounds.top ],
                      align: :right,
                      size: 12,
                      page_filter: :all
    end
  end

  private

  def generate_table(pdf)
    data = [
      [
        { content: "Naht Nr.\nWeld Nr.", rowspan: 2 },
        { content: "Komponente\ncomponent", rowspan: 2 },
        { content: "Materialdokumentation - material documentation", colspan: 6 },
        { content: "Schweissnahtdoku - welding\ndocu.", colspan: 2 },
        { content: "Prüfung - dokumentation - test\ndocumentation", colspan: 3 },
        { content: "Erg.-\nResult", rowspan: 2 }
      ],
      [
        "Abmess\nung\ndimensi\non",
        "Werkst\noff\nmateri\nal",
        "Charge\nHeat\nNr.",
        "Zeugnis\nCertific\nate",
        "Typ",
        "WPS",
        "Prozess\nprocess",
        "Schweisser\nWelder",
        "RT\nDatum\n/date",
        "PT\nDatum\n/date",
        "VT\nDatum\n/date"
      ]
    ]

    @welds.each do |weld|
      # First row
      data << [
        { content: weld.number, rowspan: 2 },
        weld.component,
        weld.dimension,
        weld.material,
        weld.batch_number,
        weld.material_certificate&.certificate_number,
        weld.type_code,
        weld.wps,
        weld.process,
        weld.welder,
        weld.rt_date&.strftime("%d.%m.%Y"),
        weld.pt_date&.strftime("%d.%m.%Y"),
        weld.vt_date&.strftime("%d.%m.%Y"),
        weld.result
      ]

      # Second row
      data << [
        weld.component1,
        weld.dimension1,
        weld.material1,
        weld.batch_number1,
        weld.material_certificate1&.certificate_number,
        weld.type_code1,
        weld.wps1,
        weld.process1,
        weld.welder1,
        weld.rt_date1&.strftime("%d.%m.%Y"),
        weld.pt_date1&.strftime("%d.%m.%Y"),
        weld.vt_date1&.strftime("%d.%m.%Y"),
        weld.result1
      ]
    end

    pdf.table(data) do |t|
      t.cells.style do |c|
        c.size = 7
        c.padding = [ 3, 2, 3, 2 ]  # Increased vertical padding
        c.border_width = 0.5
        c.align = :center
        c.valign = :center
      end

      # Header row styles
      t.row(0..1).style(font_style: :bold, size: 7)

      # Make header rows slightly taller
      t.row(0).min_height = 25
      t.row(1).min_height = 25
    end
  end

  def generate_footer(pdf)
    pdf.move_down 15

    # Calculate available width
    available_width = pdf.bounds.width
    column_width = available_width / 3  # Split into three equal columns

    legend_data = [
      [
        make_legend_table(pdf, [
          [ "SW", "Vorfertigunsnaht / Shop weld" ],
          [ "FW", "Montagenaht / Field weld" ],
          [ "SWR IN/OUT", "Blindnaht: Endnähte (Probenschweißcoupons rein/raus) / Blind and closure welds (Sample weld coupons IN/OUT)" ],
          [ "RW", "Reparatur / Repaired weld seam" ],
          [ "CW", "Schnitt / Cutted weld seam" ]
        ], column_width - 10),
        make_legend_table(pdf, [
          [ "HW", "Handnaht / Hand weld" ],
          [ "OW", "Bei Orbitalschweißungen sind die Seriennummern der Schweißmaschine und der Zange einzutragen / For orbital welding the serial numbers of the welding machine and of the welding head has to be filed" ],
          [ "VT", "Sichtprüfung innen&außen / Visual Testing inside&outside" ],
          [ "VTE", "Indirekte Sichtprüfung mittels Endoskop / Indirect Visual Testing by Boroscope" ]
        ], column_width - 10),
        make_legend_table(pdf, [
          [ "O²", "Restsauerstoffmessung / Residual Oxygen Measurement" ],
          [ "RT", "Durchstrahlungsprüfung / Radiographic Testing" ],
          [ "WC", "Neu Schweiss Start Produktion Referenznaht / NewWelding at (Re)Start or Production WeldCoupon" ],
          [ "n.e.", "nicht erforderlich / not applicable" ]
        ], column_width - 10)
      ]
    ]

    pdf.table(legend_data, width: available_width) do |t|
      t.cells.padding = [ 0, 5, 0, 5 ]
      t.cells.borders = []
      t.column_widths = [ column_width, column_width, column_width ]
    end
  end

  private

  def make_legend_table(pdf, data, width)
    # Calculate widths for the two columns
    code_width = width * 0.15  # 15% for the code
    desc_width = width * 0.85  # 85% for the description

    pdf.make_table(data,
      width: width,
      cell_style: {
        borders: [],
        padding: [ 2, 2, 2, 2 ],
        size: 8,
        inline_format: true
      }
    ) do |t|
      t.cells.borders = []
      t.column(0).font_style = :bold
      t.column(0).width = code_width
      t.column(1).width = desc_width
      t.cells.align = :left
    end
  end
end
