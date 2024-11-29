class AddQrCodePositionToIsometries < ActiveRecord::Migration[7.2]
  def change
    add_column :isometries, :qr_position, :string
    add_column :isometries, :qr_x_coordinate, :integer, default: -220  # -20 - QR width(200)
    add_column :isometries, :qr_y_coordinate, :integer, default: 20
  end
end
