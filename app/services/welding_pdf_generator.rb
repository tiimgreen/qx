require "prawn"
require "prawn/templates"
require "prawn/table"
require "rqrcode"

class WeldingPdfGenerator
  include QrCodeable

  COLUMN_WIDTHS = [
    45,  # Weld Nr.
    70,  # Component
    65,  # Dimension
    60,  # Material
    65,  # Heat Nr.
    60,  # Certificate (wider)
    70,  # Process
    70,  # Welder
    75,  # RT / Date
    75,  # PT / Date
    75,  # VT / Date
    40   # Erg
  ].freeze

  def initialize(isometry)
    @isometry = isometry
    @welds = isometry.weldings
    @additional_empty_rows = isometry.respond_to?(:additional_empty_rows) ? isometry.additional_empty_rows.to_i : 0
    @page_width = 842  # A4 landscape width
    @page_height = 595 # A4 landscape height
  end

  def generate
    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: [ 40, 30, 40, 30 ]) do |pdf|
      # Set up repeating header for all pages
      pdf.repeat(:all) do
        # Company logo on the left
        pdf.image "#{Rails.root}/app/assets/images/logo.png", width: 120, at: [ 0, pdf.bounds.top ]

        # Add QR code to the top right
        qr_temp_file = Tempfile.new([ "qr", ".png" ])
        begin
          qr_data = "#{Rails.application.routes.url_helpers.project_isometry_url(project_id: @isometry.project_id, id: @isometry.id, host: Rails.application.routes.default_url_options[:host])}"
          generate_qr_code_image(qr_data, qr_temp_file.path)
          pdf.image qr_temp_file.path, at: [ pdf.bounds.width - 50, pdf.bounds.top ], width: 50
        ensure
          qr_temp_file.close
          qr_temp_file.unlink
        end

        # Header text content
        pdf.bounding_box([ 0, pdf.bounds.top - 40 ], width: pdf.bounds.width, height: 40) do
          pdf.text "<b>Isometrie / Isometric:</b> #{@isometry.line_id}", size: 11, inline_format: true
          pdf.text "<b>Projekt Nr. / Project No.:</b> #{@isometry.project.project_number}", size: 11, inline_format: true
          pdf.text "<b>QXD Dok. Nr. / QXD Doc. No.:</b> 3.40_PP_006V01", size: 11, inline_format: true
        end

        # Title
        pdf.text_box "Protokoll Schweissnaht / Weldlog", size: 14, style: :bold, align: :center,
          at: [ 0, pdf.bounds.top - 65 ], width: pdf.bounds.width
      end

      # Content area (adjust height to leave space for legend)
      pdf.bounding_box([ 0, pdf.bounds.top - 110 ], width: pdf.bounds.width, height: pdf.bounds.height - 160) do
        generate_table(pdf)
      end

      # Set up footer for all pages at the absolute bottom
      pdf.repeat(:all) do
        # Position footer at the bottom margin
        pdf.bounding_box([ 0, pdf.margin_box.bottom + 45 ], width: pdf.bounds.width, height: 45) do
          # Draw a line above footer
          pdf.move_down 3

          # Calculate column widths for 4 columns
          column_width = pdf.bounds.width / 4

          # Create legend data in 4 columns with German/English text
          legend_data = [
            [
              make_legend_table(pdf, [ [ "SW", "Vorfertigunsnaht / Shop weld" ], [ "FW", "Montagenaht / Field weld" ] ], column_width - 5, 6),
              make_legend_table(pdf, [ [ "RW", "Reparaturnaht / Repaired weld" ], [ "VT", "Sichtprüfung / Visual Testing" ] ], column_width - 5, 6),
              make_legend_table(pdf, [ [ "RT", "Durchstrahlungsprüfung / Radiographic Testing" ], [ "N/A", "Nicht anwendbar / Not applicable" ] ], column_width - 5, 6),
              make_legend_table(pdf, [ [ "e", "Erfüllt / Accepted" ], [ "ne", "Nicht erfüllt / Not Accepted" ] ], column_width - 5, 6)
            ]
          ]

          # Create the table
          pdf.table(legend_data, width: pdf.bounds.width) do |t|
            t.cells.padding = [ 0, 2, 0, 2 ]
            t.cells.borders = []
            t.column_widths = [ column_width ] * 4
          end
        end
      end

      # Calculate total pages needed (exactly 10 welds per page)
      base_pages = (@welds.length.to_f / 10).ceil
      extra_pages = @additional_empty_rows.positive? ? 1 : 0
      total_pages = [ 1, base_pages + extra_pages ].max

      # Add page numbers
      pdf.number_pages "Seite <page> von #{total_pages}",
        at: [ pdf.bounds.right - 150, pdf.margin_box.bottom + 10 ],
        width: 150,
        align: :right,
        size: 8
    end
  end

  private

  def generate_table(pdf)
    header_rows = [
      [
        { content: "Naht Nr.\nWeld Nr.", rowspan: 2 },
        { content: "Komponente\nComponent", rowspan: 2 },
        { content: "Materialdokumentation - Material Documentation", colspan: 4 },
        { content: "Schweissnahtdoku - Welding Documentation", colspan: 2 },
        { content: "Prüfung - Dokumentation - Test Documentation", colspan: 4 }
      ],
      [
        "Abmessung\nDimension",
        "Werkstoff\nMaterial",
        "Charge\nHeat Nr.",
        "Zeugnis\nCertificate",
        "Prozess\nProcess",
        "Schweisser\nWelder",
        "RT / Date",
        "PT / Date",
        "VT / Date",
        "Erg\nres"
      ]
    ]

    # Split welds into chunks of exactly 10
    welds_array = @welds.to_a

    while welds_array.any?
      # Take exactly 10 welds or all remaining welds if less than 10
      weld_chunk = welds_array.shift(10)
      data = header_rows.dup

      weld_chunk.each do |weld|
        # First row
        data << [
          { content: weld.number, rowspan: 2 },
          weld.component,
          weld.dimension,
          weld.material,
          weld.batch_number,
          weld.material_certificate&.certificate_number,
          { content: "[#{weld.is_orbital ? 'X' : ' '}] #{weld.process}", inline_format: true },
          weld.welder,
          weld.rt_done_by.presence,
          weld.pt_done_by.presence,
          weld.vt_done_by.presence,
          { content: weld.result, rowspan: 2 }
        ]

        # Second row
        data << [
          weld.component1,
          weld.dimension1,
          weld.material1,
          weld.batch_number1,
          weld.material_certificate1&.certificate_number,
          { content: "[#{weld.is_manuell ? 'X' : ' '}] #{weld.process1}", inline_format: true },
          weld.welder1&.strftime("%d.%m.%Y"),
          weld.rt_date1&.strftime("%d.%m.%Y"),
          weld.pt_date1&.strftime("%d.%m.%Y"),
          weld.vt_date1&.strftime("%d.%m.%Y")
        ]
      end

      pdf.table(data, width: pdf.bounds.width) do |t|
        t.cells.style(
          size: 8,
          align: :center,
          valign: :center,
          padding: [ 2, 1, 2, 1 ],  # Consistent padding top/bottom
          inline_format: true
        )

        # Set specific column widths to prevent truncation
        t.column_widths = COLUMN_WIDTHS

        # Style header rows (first two rows)
        t.row(0..1).style(
          font_style: :bold,
          background_color: "FFFFFF"
        )

        # Ensure consistent row heights
        t.row(2..-1).height = 15 if t.row(2)  # Set fixed height for data rows
      end

      # Add a new page if there are more welds to show
      if welds_array.any?
        pdf.start_new_page
        pdf.move_down 0  # Match the initial top margin on new pages
      end
    end

    # Append an extra page with empty rows if requested
    if @additional_empty_rows.positive?
      pdf.start_new_page

      header_rows = [
        [
          { content: "Naht Nr.\nWeld Nr.", rowspan: 2 },
          { content: "Komponente\nComponent", rowspan: 2 },
          { content: "Materialdokumentation - Material Documentation", colspan: 4 },
          { content: "Schweissnahtdoku - Welding Documentation", colspan: 2 },
          { content: "Prüfung - Dokumentation - Test Documentation", colspan: 4 }
        ],
        [
          "Abmessung\nDimension",
          "Werkstoff\nMaterial",
          "Charge\nHeat Nr.",
          "Zeugnis\nCertificate",
          "Prozess\nProcess",
          "Schweisser\nWelder",
          "RT / Date",
          "PT / Date",
          "VT / Date",
          "Erg\nres"
        ]
      ]

      # Build empty data rows (each logical weld takes two table rows)
      empty_data_rows = []
      @additional_empty_rows.times do
        # first row with rowspan cells for first and last column
        empty_data_rows << [
          { content: "", rowspan: 2 },           # Weld Nr.
          "", "", "", "", "", "", "", "", "", "",  # 11 blanks for columns 1-11
          { content: "", rowspan: 2 }            # Erg / res
        ]

        # second row (completes the split columns)
        empty_data_rows << [ "", "", "", "", "", "", "", "", "", "" ]
      end

      table_data = header_rows + empty_data_rows

      pdf.table(table_data, width: pdf.bounds.width) do |t|
        t.cells.size = 8
        t.cells.align = :center
        t.row(0..1).font_style = :bold
        t.column_widths = COLUMN_WIDTHS
        # Ensure empty rows have same height as data rows
        t.row(2..-1).height = 15 if t.row(2)
      end
    end
  end

  private

  def make_legend_table(pdf, data, width, font_size = 8)
    # Calculate widths for the two columns
    code_width = width * 0.2  # 20% for the code
    desc_width = width * 0.8  # 80% for the description

    pdf.make_table(data,
      width: width,
      cell_style: {
        borders: [],
        padding: [ 1, 1, 1, 1 ],
        size: font_size,
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
