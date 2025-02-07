require "prawn"
require "prawn/templates"
require "prawn/table"
require "rqrcode"

class WeldingPdfGenerator
  include QrCodeable

  def initialize(isometry)
    @isometry = isometry
    @welds = isometry.weldings
    @page_width = 842  # A4 landscape width
    @page_height = 595 # A4 landscape height
  end

  def generate
    Prawn::Document.new(page_size: "A4", page_layout: :landscape, margin: [ 30, 30, 30, 30 ]) do |pdf|
      # Set up repeating header for all pages
      pdf.repeat(:all) do
        pdf.bounding_box([ 0, pdf.bounds.top ], width: pdf.bounds.width, height: 80) do
          # Company logo on the left
          pdf.image "#{Rails.root}/app/assets/images/logo.png", width: 120, position: :left, vposition: :top

          # Add QR code to the top right
          qr_temp_file = Tempfile.new([ "qr", ".png" ])
          begin
            qr_data = "#{Rails.application.routes.url_helpers.project_isometry_url(project_id: @isometry.project_id, id: @isometry.id, host: Rails.application.routes.default_url_options[:host])}"
            generate_qr_code_image(qr_data, qr_temp_file.path)

            # Use fixed position for landscape A4
            x = pdf.bounds.width - 50  # Position from right margin
            y = pdf.bounds.top - 20    # Position from top margin

            pdf.image qr_temp_file.path, at: [ x, y ], width: 50
          ensure
            qr_temp_file.close
            qr_temp_file.unlink
          end


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
    header_rows = [
      [
        { content: "Naht Nr.\nWeld Nr.", rowspan: 2 },
        { content: "Com...", rowspan: 2 },
        { content: "Materialdokumentation - Mat... Doc...", colspan: 4 },
        { content: "Schweissnahtdoku - Welding Doc...", colspan: 2 },
        { content: "Prüfung - Dokumentation - Test Documentation", colspan: 4 }
      ],
      [
        "Dim...",
        "Mat...",
        "Charge\nHeat Nr.",
        "Zeugnis\nCertificate",
        "Pro...",
        "Schweisser\nWelder",
        "RT / Date",
        "PT / Date",
        "VT / Date",
        "Erg\nres"
      ]
    ]

    # Split welds into chunks of 5 (since each weld takes 2 rows)
    @welds.each_slice(10) do |weld_chunk|
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
          weld.rt_done_by,
          weld.pt_done_by,
          weld.vt_done_by,
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
          padding: [ 2, 1, 4, 1 ],
          inline_format: true
        )

        # Style header rows (first two rows)
        t.row(0..1).style(
          font_style: :bold
        )
      end

      pdf.move_down 20

      # Add a new page if there are more welds to show
      if weld_chunk != @welds.each_slice(5).to_a.last
        pdf.start_new_page
      end
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
