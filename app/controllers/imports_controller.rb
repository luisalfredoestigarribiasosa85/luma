require "csv"

class ImportsController < ApplicationController
  # GET /imports/new — form to upload a CSV of products
  def new; end

  # POST /imports — parse + validate; without confirm shows preview, with confirm imports.
  def create
    file = params[:file]
    if params[:confirm] == "1"
      content = params[:csv_content]
      if content.blank?
        flash.now[:alert] = "El contenido del archivo ya no está disponible. Subí de nuevo el CSV."
        render :new, status: :unprocessable_entity
        return
      end

      @importer = ProductImporter.new(nil, account: current_account)
      @importer.content = content
      @importer.import!

      count = @importer.imported_count
      errors_count = @importer.rows.count - count
      notice = "Importación completada: #{count} producto(s) creado(s)."
      if errors_count.positive?
        sample = @importer.errors.values.first(3).map { |m| m.split("; ").first }.uniq
        notice += " #{errors_count} fila(s) con errores (ej.: #{sample.join("; ")})."
      end
      redirect_to products_path, notice: notice
    else
      unless file.present? && file.respond_to?(:read)
        flash.now[:alert] = "Seleccioná un archivo CSV"
        render :new, status: :unprocessable_entity
        return
      end

      if file.respond_to?(:original_filename)
        ext = File.extname(file.original_filename.to_s).downcase
        unless [ ".csv", ".xlsx", ".xls" ].include?(ext)
          flash.now[:alert] = "Formato no soportado (#{ext.presence || "desconocido"}). Usá un archivo CSV (.csv) o de Excel (.xlsx / .xls)."
          render :new, status: :unprocessable_entity
          return
        end
      end

      @importer = ProductImporter.new(file, account: current_account)
      @importer.preview
      if @importer.rows.empty? || !@importer.preview_ok?
        snippet = @importer.original_content.to_s.lines.first(3).join.strip.truncate(120)
        flash.now[:alert] = "No se encontraron filas para importar. Revisá que el archivo tenga la primera fila con cabeceras (nombre, precio, etc.). Contenido detectado: «#{snippet}»"
        render :new, status: :unprocessable_entity
      else
        render :preview
      end
    end
  end

  # GET /imports/template — downloadable CSV with the expected columns.
  def template
    headers = ProductImporter::EXPECTED_HEADERS
    csv = CSV.generate do |row|
      row << headers
      row << [ "Remera oversize", "REM-13", "Ropa", "45000", "89000", "20", "5", "unidad", "M", "negro" ]
      row << [ "Remera oversize", "REM-14", "Ropa", "45000", "89000", "18", "5", "unidad", "L", "negro" ]
    end

    send_data "\xEF\xBB\xBF#{csv}".force_encoding("UTF-8"),
      filename: "plantilla_productos.csv",
      type: "text/csv; charset=utf-8"
  end
end