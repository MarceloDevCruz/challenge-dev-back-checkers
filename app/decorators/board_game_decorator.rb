class BoardGameDecorator < Draper::Decorator
  delegate_all

  BOARD_SIZE = 8
  EMPTY_CELL = " "

  def board_grid
    raw_grid = object.board_state
    return default_empty_grid unless raw_grid.is_a?(Array) && raw_grid.any?

    (0...BOARD_SIZE).map do |row|
      (0...BOARD_SIZE).map do |col|
        format_cell(raw_grid.dig(row, col))
      end
    end
  end

  def board_view
    rows = board_grid.each_with_index.map do |cells, row_idx|
      formatted_cells = cells.map { |c| c == EMPTY_CELL ? "__" : c.ljust(2) }
      "#{row_idx} | #{formatted_cells.join(" | ")} |"
    end

    header = "    " + (0...BOARD_SIZE).map { |c| c.to_s.ljust(2) }.join("   ")
    divider = "  +" + ([ "----" ] * BOARD_SIZE).join("+") + "+"

    [ header, divider, *rows, divider ]
  end

  private

  def format_cell(cell)
    return EMPTY_CELL unless cell.is_a?(Hash)

    player = cell["player"] || cell[:player]
    type   = cell["type"] || cell[:type]
    return EMPTY_CELL unless player

    code = "p#{player}"
    type.to_s == "king" ? code.upcase : code
  end

  def default_empty_grid
    Array.new(BOARD_SIZE) { Array.new(BOARD_SIZE, EMPTY_CELL) }
  end
end
