# Service object that parses a CSV of products and previews/imports them
# for a given account. Columns are matched by their header (Spanish-first,
# accents/underscores normalized) and validated per-row before saving.
require "csv"

class ProductImporter
  EXPECTED_HEADERS = %w[nombre sku categoria costo precio stock minimo unidad talle color].freeze

  attr_reader :rows, :imported_count, :errors

  def initialize(file, account:)
    @file = file
    @account = account
    @original_content = normalize_encoding(file_content(file))
    @catalog = parse_content(@original_content)
    @rows = []
    @errors = {}
    @imported_count = 0
  end

  # Allows re-parsing the same CSV content on a subsequent request (the confirm
  # step), when the original upload file is no longer available.
  def content=(raw)
    @original_content = normalize_encoding(raw)
    @catalog = parse_content(@original_content)
    @rows = []
    @errors = {}
    @imported_count = 0
  end

  def original_content
    @original_content
  end

  def preview
    build_rows
    self
  end

  # Imports valid rows, skipping invalid ones. Returns the count imported and
  # fills @errors with per-row messages for reporting.
  def import!
    build_rows

    @rows.each do |row|
      if row[:errors].present?    # rows flagged invalid during preview
        @errors[row[:index]] = row[:errors].join("; ")
        next
      end

      product = build_product(row[:attrs])
      next unless product

      if save_product(product, row)
        @imported_count += 1
      else
        @errors[row[:index]] = product.errors.full_messages.to_sentence
      end
    end

    self
  end

  def valid_rows
    @valid_rows ||= @rows.reject { |r| r[:errors].present? }
  end

  def fatal_error
    @fatal_error
  end

  def preview_ok?
    @rows.any? && @fatal_error.nil?
  end

  private

  # Extracts the raw tabular content as a single CSV string. Native Excel
  # files (.xlsx/.xls) are flattened into CSV via Roo so the rest of the
  # pipeline (which works on CSV text) can be reused.
  def file_content(file)
    return nil unless file.respond_to?(:read)

    filename = file.respond_to?(:original_filename) ? file.original_filename.to_s : ""
    ext = File.extname(filename).downcase

    if [ ".xlsx", ".xls" ].include?(ext)
      return nil unless file.respond_to?(:path)
      xlsx_to_csv(file.path, ext)
    else
      file.read
    end
  end

  def xlsx_to_csv(path, ext)
    require "roo"
    spreadsheet = Roo::Spreadsheet.open(path, extension: ext.delete_prefix(".").to_sym)
    spreadsheet.sheets.each do |sheet_name|
      sheet = spreadsheet.sheet(sheet_name)
      buf = +""
      sheet.each_row_streaming(pad_cells: true).each do |cells|
        buf << CSV.generate_line(cells.map { |c| c.value.to_s })
      end
      return buf # only first sheet
    end
    ""
  rescue StandardError
    nil
  end

  # Reads the CSV, returning an array of hashes keyed by normalized header.
  # Auto-detects the delimiter and treats the first non-blank line as headers.
  def parse_content(content)
    content = normalize_encoding(content)
    content = content.sub(/\A\xEF\xBB\xBF/, "") # strip UTF-8 BOM

    return [] if content.blank?

    lines = content.lines.map(&:strip).reject(&:empty?)
    return [] if lines.empty?

    delimiter = detect_delimiter(lines.first)

    headers = split_line(lines.first, delimiter).map { |h| normalize_header(h) }
    return [] if headers.empty? || headers.none?(&:present?)

    rows = []
    current_line = 2
    lines[1..].each do |line|
      values = split_line(line, delimiter)
      pair = {}
      headers.each_with_index do |header, i|
        pair[header] = (values[i] || "").to_s.strip
      end
      rows << [ current_line, pair ]
      current_line += 1
    end
    rows
  rescue CSV::MalformedCSVError => e
    @fatal_error = "El archivo no es un CSV válido: #{e.message}"
    []
  end

  def detect_delimiter(header_line)
    return ";" if header_line.count(";") > header_line.count(",")
    ","
  end

  def split_line(line, delimiter)
    CSV.parse_line(line, col_sep: delimiter) || []
  end

  # Ensures the string is valid UTF-8, converting transcode-able content
  # (e.g. Latin-1/Windows-1252 from Excel) instead of raising on bad bytes.
  def normalize_encoding(content)
    content = content.to_s.dup
    detected = content.force_encoding("UTF-8")
    return detected if detected.valid_encoding?

    content.force_encoding(Encoding::ISO_8859_1)
      .encode(Encoding::UTF_8)
  rescue EncodingError
    content.scrub
  end

  def build_rows
    return @rows unless @rows.empty?

    @catalog.each do |index, attrs|
      errors_for_row = validate(attrs)
      @rows << {
        index: index,
        attrs: attrs,
        errors: errors_for_row
      }
    end
    @rows
  end

  def validate(attrs)
    messages = []

    messages << "falta el nombre" if attrs[ "nombre" ].blank?

    unless attrs[ "costo" ].blank? || attrs[ "costo" ] =~ /\A\d+(\.\d+)?\z/
      messages << "costo inválido (#{attrs[ "costo" ]})"
    end

    unless attrs[ "precio" ].blank? || attrs[ "precio" ] =~ /\A\d+(\.\d+)?\z/
      messages << "precio inválido (#{attrs[ "precio" ]})"
    end

    stock = attrs[ "stock" ]
    if stock.present? && stock !~ /\A\d+\z/
      messages << "stock inválido (#{stock})"
    end

    sku = attrs[ "sku" ].to_s.strip
    if sku.present? && @account.products.where(sku: sku).exists?
      messages << "SKU #{sku} ya existe"
    end

    if sku.present?
      seen = @seen_skus ||= {}
      if seen[ sku ]
        messages << "SKU #{sku} repetido en el archivo"
      else
        seen[ sku ] = true
      end
    end

    messages
  end

  def build_product(attrs)
    @account.products.build(
      name: attrs[ "nombre" ],
      sku: attrs[ "sku" ].presence,
      cost_price: integer_or_zero(attrs[ "costo" ]),
      price: integer_or_zero(attrs[ "precio" ]),
      stock: integer_or_zero(attrs[ "stock" ]),
      min_stock: integer_or_zero(attrs[ "minimo" ]),
      unit: attrs[ "unidad" ].presence || "unidad",
      size: attrs[ "talle" ].presence,
      color: attrs[ "color" ].presence,
      category: find_or_build_category(attrs[ "categoria" ])
    )
  end

  def save_product(product, row)
    if product.save
      Rails.logger.info "IMPORT: fila #{row[:index]} OK -> #{product.name}"
      true
    else
      msg = product.errors.full_messages.to_sentence
      Rails.logger.warn "IMPORT: fila #{row[:index]} FALLO: #{msg} (attrs=#{row[:attrs].inspect})"
      @errors[row[:index]] = msg
      false
    end
  end

  def find_or_build_category(name)
    return nil if name.blank?

    @account.categories.find_or_create_by!(name: name)
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def integer_or_zero(value)
    value.present? ? value.to_i : 0
  end

  def normalize_header(header)
    header.to_s.downcase
      .tr("áéíóúüñ", "aeiouun")
      .tr("_ ", "")
      .strip
  end
end