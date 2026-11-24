# Three teaching terms per year; abbreviations respect the brief's 10-character limit.
class Semester
  TERMS = %w[Spr Sum Fall].freeze
  def self.order(value)
    match = /\A(Spr|Sum|Fall) (\d{4})\z/.match(value.to_s)
    raise ArgumentError, "Use Spr, Sum or Fall followed by a four-digit year (e.g. Fall 2026)" unless match
    match[2].to_i * 3 + TERMS.index(match[1])
  end

  def self.label(order)
    "#{TERMS[order % 3]} #{order / 3}"
  end

  def self.current(date = Date.current)
    date.year * 3 + (date.month <= 5 ? 0 : date.month <= 8 ? 1 : 2)
  end

  def self.recent(date = Date.current)
    current(date).downto(current(date) - 4).map { |value| label(value) }
  end
end
