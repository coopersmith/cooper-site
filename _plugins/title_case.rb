# frozen_string_literal: true

require "set"

# `titlecase` Liquid filter — Title Case for the Media Diet.
#
# Media notes are authored in Obsidian and mirrored into `_notes/` at build
# time (see CLAUDE.md), so we can't fix casing at the source. Worse, most
# movie/show/album notes carry no `title:` in their front matter, so Jekyll
# derives one from the filename with `Utils.titleize_slug`, which runs Ruby's
# `String#capitalize` — sentence-casing "American Gangster (2007)" down to
# "American gangster (2007)". Books, which do set an explicit title, escape
# this but then read inconsistently against the mangled majority.
#
# This filter normalises any media title to Title Case at render time. The
# author's per-note styling in other collections is untouched — it's applied
# only on the Media Diet views (see `_pages/media.md` and `_layouts/media.html`).
#
# Rules:
#   * Minor words (articles, coordinating conjunctions, short prepositions) are
#     lowercased — unless they're the first or last word, or open a subtitle
#     after a colon.
#   * A word that already carries a capital past its first letter (LaserWriter,
#     iPhone) or is all-caps (roman numerals like "II", acronyms like "DTF",
#     "MSG") is left exactly as written — never flattened.
#   * Hyphenated compounds capitalise each part ("X-Men", "24-Hour").
module TitleCaseFilter
  # Words kept lowercase mid-title. Deliberately short — only the words that
  # read wrong when capitalised. Prepositions of four+ letters stay capitalised.
  SMALL_WORDS = %w[
    a an and as at but by en for if in nor of on or per so the to up v v. via vs vs. yet
  ].to_set.freeze

  def titlecase(input)
    return input if input.nil?

    str = input.to_s
    return str if str.strip.empty?

    tokens = str.split(/(\s+)/) # keep the whitespace runs so spacing survives
    words = tokens.each_index.select { |i| i.even? } # non-whitespace slots
    first = words.first
    last = words.last

    after_colon = false
    tokens.each_with_index do |tok, i|
      if i.odd? # whitespace — carry the colon flag across it
        next
      end

      force_major = i == first || i == last || after_colon
      tokens[i] = transform_word(tok, force_major)
      after_colon = tok.rstrip.end_with?(":")
    end

    tokens.join
  end

  private

  def transform_word(word, force_major)
    return word unless word =~ /[A-Za-z]/

    if word.include?("-")
      # Each side of a hyphenated compound is capitalised in Title Case.
      return word.split("-", -1).map { |part| transform_segment(part, true) }.join("-")
    end

    transform_segment(word, force_major)
  end

  def transform_segment(segment, force_major)
    core = segment.gsub(/[^A-Za-z]/, "")
    return segment if core.empty?

    # Preserve intentional casing: internal capitals (LaserWriter, iPhone) and
    # all-caps tokens (II, DTF). Both have a capital somewhere past the first
    # letter; a plain "Word" or "word" does not.
    return segment if core[1..] =~ /[A-Z]/

    if !force_major && SMALL_WORDS.include?(core.downcase)
      return segment.downcase
    end

    down = segment.downcase
    # Capitalise the opening letter, lowercase the rest — but only when a letter
    # actually opens the word (optionally behind quotes/brackets). A leading
    # digit means the letters are an ordinal or unit suffix ("37th", "24hr"),
    # which stay lowercase.
    return down unless down =~ /\A[^0-9A-Za-z]*[a-z]/

    down.sub(/[a-z]/) { |c| c.upcase }
  end
end

Liquid::Template.register_filter(TitleCaseFilter)

# Recover the author's filename casing for Media Diet notes.
#
# Most movie/show/album notes set no `title:`, so Jekyll derives one with
# `Utils.titleize_slug`, which runs Ruby's `String#capitalize` over the
# filename — collapsing "Creed II" to "Creed ii", "DTF St Louis" to "Dtf st
# louis", and dropping the " - " in "Frank Ocean - channel ORANGE". Roman
# numerals, acronyms, and separators are lost before any Liquid filter can see
# them, so `titlecase` alone can only produce "Creed Ii" / "Dtf St Louis".
#
# This generator runs first (`:highest`, ahead of the TV plugin at `:high`) and,
# for every MediaDiet note whose title is exactly Jekyll's auto-derived one,
# swaps in the raw filename — the author's own Title Case. Notes that set an
# explicit title (most books, with their colon subtitles) are left untouched.
# The `titlecase` filter then normalises minor words on top of the good casing.
class MediaDietTitleRecovery < Jekyll::Generator
  priority :highest

  MEDIA_PATH = "MediaDiet/"

  def generate(site)
    site.collections["notes"].docs.each do |doc|
      next unless doc.path.include?(MEDIA_PATH)

      basename = File.basename(doc.basename, ".*").sub(/\.*\z/, "")
      # Only override when the current title is the one Jekyll invented from the
      # filename — i.e. the note carries no hand-written title of its own.
      next unless doc.data["title"].to_s == Jekyll::Utils.titleize_slug(basename)

      doc.data["title"] = basename
    end
  end
end
