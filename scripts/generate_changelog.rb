#!/usr/bin/env ruby
# frozen_string_literal: true

# generate_changelog.rb
# ---------------------------------------------------------------------------
# Builds _data/changelog.yml from the repository's merged pull requests, using
# Claude to turn each PR into a short, human-readable "what & why" sentence.
#
# It is INCREMENTAL: PRs already present in _data/changelog.yml are left
# untouched, so re-running only summarizes newly-merged PRs (and preserves any
# summaries you've hand-edited). The generated file is committed to the repo,
# so the Jekyll/Netlify build itself never calls any API and stays deterministic.
#
# Usage:
#   export ANTHROPIC_API_KEY=sk-ant-...   # required (summaries)
#   export GITHUB_TOKEN=ghp_...           # optional (raises API rate limits)
#   ruby scripts/generate_changelog.rb
#
# Environment options:
#   CHANGELOG_REPO    owner/name to read PRs from   (default coopersmith/cooper-site)
#   CHANGELOG_MODEL   Claude model for summaries     (default claude-sonnet-5)
#   CHANGELOG_FORCE   set to "1" to re-summarize every PR, ignoring existing entries
#   CHANGELOG_LIMIT   only process the N most recent new PRs (default: all)
#
# Uses only the Ruby standard library — no extra gems required.
# ---------------------------------------------------------------------------

require 'net/http'
require 'json'
require 'uri'
require 'yaml'
require 'time'
require 'set'

REPO       = ENV.fetch('CHANGELOG_REPO', 'coopersmith/cooper-site')
MODEL      = ENV.fetch('CHANGELOG_MODEL', 'claude-sonnet-5')
FORCE      = ENV['CHANGELOG_FORCE'] == '1'
LIMIT      = ENV['CHANGELOG_LIMIT']&.to_i
DATA_PATH  = File.expand_path('../_data/changelog.yml', __dir__)
CATEGORIES = %w[feature fix design refactor content chore polish].freeze

GH_TOKEN   = ENV['GITHUB_TOKEN']
AI_KEY     = ENV['ANTHROPIC_API_KEY']

# --- tiny HTTP helpers -----------------------------------------------------

def gh_get(path, query = {})
  uri = URI("https://api.github.com#{path}")
  uri.query = URI.encode_www_form(query) unless query.empty?
  req = Net::HTTP::Get.new(uri)
  req['Accept'] = 'application/vnd.github+json'
  req['User-Agent'] = 'cooper-site-changelog'
  req['Authorization'] = "Bearer #{GH_TOKEN}" if GH_TOKEN && !GH_TOKEN.empty?
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  unless res.is_a?(Net::HTTPSuccess)
    abort "GitHub API #{res.code} for #{path}: #{res.body.to_s[0, 200]}"
  end
  JSON.parse(res.body)
end

def anthropic_summary(pr, diffstat)
  uri = URI('https://api.anthropic.com/v1/messages')
  req = Net::HTTP::Post.new(uri)
  req['x-api-key'] = AI_KEY
  req['anthropic-version'] = '2023-06-01'
  req['content-type'] = 'application/json'

  system_prompt = <<~SYS
    You write a personal website's changelog. Given a merged pull request, return
    a single JSON object describing it for a general reader (no jargon, no file
    names, no "this PR"). Focus on WHAT changed and WHY it mattered.

    Return ONLY minified JSON with exactly these keys:
      "title":    a short human headline, <= 60 chars, sentence case, no trailing period
      "summary":  1-2 warm, plain-English sentences (<= 320 chars) on what & why
      "category": one of #{CATEGORIES.join(', ')}
    No markdown, no code fences, no extra keys.
  SYS

  body = (pr['body'] || '').gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip[0, 1500]
  user = <<~USR
    PR ##{pr['number']}: #{pr['title']}
    Merged: #{pr['merged_at']}
    Files changed (#{diffstat[:count]}): #{diffstat[:files].join(', ')}
    Net lines: +#{diffstat[:additions]} / -#{diffstat[:deletions]}

    Description:
    #{body.empty? ? '(none)' : body}
  USR

  payload = {
    model: MODEL,
    max_tokens: 400,
    system: system_prompt,
    messages: [{ role: 'user', content: user }]
  }
  req.body = JSON.dump(payload)

  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  unless res.is_a?(Net::HTTPSuccess)
    warn "  ! Anthropic API #{res.code}: #{res.body.to_s[0, 200]} — skipping ##{pr['number']}"
    return nil
  end

  text = JSON.parse(res.body).dig('content', 0, 'text').to_s
  json = text[/\{.*\}/m]
  return nil unless json

  parsed = JSON.parse(json)
  cat = parsed['category'].to_s.downcase
  cat = 'feature' unless CATEGORIES.include?(cat)
  {
    'number'   => pr['number'],
    'date'     => Time.parse(pr['merged_at']).strftime('%Y-%m-%d'),
    'title'    => parsed['title'].to_s.strip,
    'category' => cat,
    'summary'  => parsed['summary'].to_s.strip,
    'url'      => pr['html_url']
  }
rescue JSON::ParserError => e
  warn "  ! Could not parse model output for ##{pr['number']}: #{e.message}"
  nil
end

# --- fetch every merged PR (paginated) ------------------------------------

def merged_pull_requests
  prs = []
  page = 1
  loop do
    batch = gh_get("/repos/#{REPO}/pulls",
                   state: 'closed', per_page: 100, page: page,
                   sort: 'updated', direction: 'desc')
    break if batch.empty?

    prs.concat(batch.select { |p| p['merged_at'] })
    break if batch.size < 100

    page += 1
  end
  prs
end

def diffstat_for(number)
  files = gh_get("/repos/#{REPO}/pulls/#{number}/files", per_page: 100)
  {
    count: files.size,
    files: files.map { |f| f['filename'] }.first(12),
    additions: files.sum { |f| f['additions'].to_i },
    deletions: files.sum { |f| f['deletions'].to_i }
  }
rescue StandardError
  { count: 0, files: [], additions: 0, deletions: 0 }
end

# --- serialize back to a clean, diff-friendly YAML file --------------------

HEADER = <<~HDR
  # Changelog entries, generated from merged pull requests by
  # scripts/generate_changelog.rb (each summary is a human-readable "what & why"
  # written by Claude). This file is committed so the site build never calls any
  # API. You can hand-edit any summary/title/category — the generator only adds
  # NEW merged PRs and leaves existing entries untouched.
  #
  # Fields: number, date (YYYY-MM-DD), title, category, summary, url
  # Categories: feature, fix, design, refactor, content, chore, polish
HDR

def yq(str)
  '"' + str.to_s.gsub('\\', '\\\\\\\\').gsub('"', '\\"') + '"'
end

def wrap(text, indent)
  words = text.split(/\s+/)
  lines = []
  cur = +''
  words.each do |w|
    if (cur.length + w.length + 1) > (80 - indent.length) && !cur.empty?
      lines << cur
      cur = +''
    end
    cur << (cur.empty? ? '' : ' ') << w
  end
  lines << cur unless cur.empty?
  lines.map { |l| "#{indent}#{l}" }.join("\n")
end

def dump(entries)
  out = +HEADER
  out << "---\n"
  entries.each do |e|
    out << "- number: #{e['number']}\n"
    out << "  date: '#{e['date']}'\n"
    out << "  title: #{yq(e['title'])}\n"
    out << "  category: #{e['category']}\n"
    out << "  summary: >-\n"
    out << wrap(e['summary'], '    ') << "\n"
    out << "  url: #{e['url']}\n"
    out << "\n"
  end
  out
end

# --- main ------------------------------------------------------------------

existing = File.exist?(DATA_PATH) ? (YAML.safe_load(File.read(DATA_PATH)) || []) : []
have = existing.map { |e| e['number'] }.to_set

puts "Repo: #{REPO}  |  model: #{MODEL}  |  #{existing.size} existing entr#{existing.size == 1 ? 'y' : 'ies'}"

merged = merged_pull_requests
todo = FORCE ? merged : merged.reject { |p| have.include?(p['number']) }
todo = todo.sort_by { |p| -p['number'] }
todo = todo.first(LIMIT) if LIMIT && LIMIT.positive?

if todo.empty?
  puts 'Nothing new to summarize. Up to date.'
  exit 0
end

abort 'ANTHROPIC_API_KEY is required to summarize new PRs.' if AI_KEY.nil? || AI_KEY.empty?

puts "Summarizing #{todo.size} PR#{todo.size == 1 ? '' : 's'}..."
by_number = existing.each_with_object({}) { |e, h| h[e['number']] = e }

todo.each do |pr|
  print "  ##{pr['number']} #{pr['title'][0, 50]}... "
  entry = anthropic_summary(pr, diffstat_for(pr['number']))
  next unless entry

  by_number[entry['number']] = entry
  puts "-> [#{entry['category']}] #{entry['title']}"
end

merged_entries = by_number.values.sort_by { |e| [e['date'], e['number']] }.reverse
File.write(DATA_PATH, dump(merged_entries))
puts "Wrote #{merged_entries.size} entries to #{DATA_PATH}"
