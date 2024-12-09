require "prawn"
require "prawn/templates"
require "prawn/table"

class WeldingPdfGenerator
  def initialize(isometry)
    @isometry = isometry
    @welds = isometry.weldings
  end

  def generate
    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: [ 40, 40, 40, 40 ]) do |pdf|
      generate_header(pdf)
      generate_table(pdf)
      generate_footer(pdf)
    end
  end

  private

  def generate_header(pdf)
    pdf.image "#{Rails.root}/app/assets/images/logo.png", width: 120, position: :left
    pdf.float do
      pdf.text_box "1 von 1",
                  at: [ pdf.bounds.right - 50, pdf.bounds.top ],
                  align: :right,
                  size: 12
    end

    pdf.move_down 20
    pdf.text "Isometrie / Isometric: #{@isometry.line_id}", size: 11
    pdf.text "Projekt Nr. / Project No.: #{@isometry.project.project_number}", size: 11
    pdf.move_down 10
    pdf.text "Protokoll Schweissnaht / Weldlog", size: 14, style: :bold, align: :center
    pdf.move_down 15
  end

  def generate_table(pdf)
    data = [
      [
        "",
        "",
        { content: "Materialdokumentation- material documentation", colspan: 5 },
        "",
        { content: "Schweissnahtdoku.-welding docu.", colspan: 2 },
        { content: "Prüfung-dokumentation- test documentation", colspan: 3 },
        ""
      ],
      [
        "Naht Nr.\nWeld Nr.",
        "Komponente\ncomponent",
        "Abmessung\ndimension",
        "Werkstoff\nmaterial",
        "Charge\nHeat Nr.",
        "Zeugnis\nCertificate",
        "Typ",
        "WPS",
        "Prozess\nprocess",
        "Schweisser- Welder\nDatum /date",
        "RT\nDatum /date",
        "PT\nDatum /date",
        "VT\nDatum /date",
        "Erg.- Result"
      ]
    ]

    # Add weld data with selective split rows
    @welds.each do |weld|
      data << [
        { content: weld.number, rowspan: 2 },
        weld.component,  # First part of the split Komponente cell
        weld.dimension,
        { content: weld.material, rowspan: 2 },
        weld.batch_number,
        weld.material_certificate&.certificate_number,
        { content: weld.type_code, rowspan: 2 },
        { content: weld.wps, rowspan: 2 },
        { content: weld.process, rowspan: 2 },
        weld.welder,
        weld.rt_date&.strftime("%d.%m.%Y"),
        weld.pt_date&.strftime("%d.%m.%Y"),
        weld.vt_date&.strftime("%d.%m.%Y"),
        { content: weld.result, rowspan: 2 }
      ]
      data << [
        "",  # Covered by Naht Nr. rowspan
        weld.component,  # Second part of the split Komponente cell
        weld.dimension,  # Second part of Abmessung
        "", # Covered by Werkstoff rowspan
        weld.batch_number, # Second part of Charge
        weld.material_certificate&.certificate_number, # Second part of Zeugnis
        "", # Covered by Typ rowspan
        "", # Covered by WPS rowspan
        "", # Covered by Prozess rowspan
        weld.welder, # Second part of Schweisser
        weld.rt_date&.strftime("%d.%m.%Y"), # Second part of RT Datum
        weld.pt_date&.strftime("%d.%m.%Y"), # Second part of PT Datum
        weld.vt_date&.strftime("%d.%m.%Y"), # Second part of VT Datum
        ""  # Covered by Erg. rowspan
      ]
    end

    pdf.table(data, width: pdf.bounds.width) do |t|
      t.cells.style do |c|
        c.size = 9
        c.padding = [ 4, 4, 4, 4 ]
        c.border_width = 0.5
        c.align = :center
        c.valign = :center
      end

      # Header row styles
      t.row(0..1).style(font_style: :bold)

      # Column widths
      t.column(0).width = 45  # Naht Nr.
      t.column(-1).width = 45 # Erg.

      # Date columns
      [ 10, 11, 12 ].each do |col|
        t.column(col).width = 60 if col < t.column_length
      end

      # Narrower columns
      t.column(6).width = 30 if 6 < t.column_length # Typ
      t.column(7).width = 30 if 7 < t.column_length # WPS
    end
  end

  def generate_footer(pdf)
    pdf.move_down 15

    legend_data = [
      [
        make_legend_table(pdf, [
          [ "SW", "Vorfertingungsnaht / Shop weld" ],
          [ "FW", "Montagenaht / Field weld" ],
          [ "RW", "Reparatur / Repaired weld seam" ],
          [ "CW", "Schnitt / Cutted weld seam" ]
        ]),
        make_legend_table(pdf, [
          [ "VT", "Sichtprüfung innen&außen / Visual Testing inside&outside" ],
          [ "RT", "Durchstrahlungsprüfung / Radiographic Testing" ],
          [ "O²", "Restsauerstoffmessung / Residual Oxygen Measurement" ]
        ])
      ]
    ]

    pdf.table(legend_data, cell_style: { borders: [] }) do |t|
      t.cells.padding = [ 0, 20, 0, 0 ]
    end
  end

  private

  def make_legend_table(pdf, data)
    pdf.make_table(data, cell_style: {
      borders: [],
      padding: [ 2, 5, 2, 5 ],
      size: 8
    }) do |t|
      t.column(0).font_style = :bold
      t.column(0).width = 30
    end
  end
end
