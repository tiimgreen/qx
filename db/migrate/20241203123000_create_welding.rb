class CreateWelding < ActiveRecord::Migration[7.0]
  def change
    create_table :weldings do |t|
      t.string :number        # Naht Nr.
      t.string :component     # Komponente
      t.string :dimension     # Abmessung
      t.string :material      # Werkstoff
      t.string :batch_number  # Charge
      t.references :material_certificate, null: true, foreign_key: true
      t.string :type_code     # Typ (using type_code instead of type to avoid conflicts with Rails)
      t.string :wps          # WPS
      t.string :process      # Prozess
      t.string :welder       # Schweisser
      t.datetime :rt_date    # RT Datum (Radiographic Testing date)
      t.datetime :pt_date    # PT Datum (Penetrant Testing date)
      t.datetime :vt_date    # VT Datum (Visual Testing date)
      t.string :result       # Erg. (Result)

      t.timestamps
    end

    add_index :weldings, :number
    add_index :weldings, :batch_number
  end
end
