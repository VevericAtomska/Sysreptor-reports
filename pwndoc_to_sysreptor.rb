#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'json'
require 'kramdown'
require 'securerandom'
require 'date'
require 'fileutils'

if ARGV.length != 2
  raise ArgumentError, 'Invalid argument count (2 expected)'
end

pwndoc_file = ARGV[0]
sysreptor_folder = ARGV[1]

begin
  pwndoc_data = YAML.load_file(pwndoc_file)
rescue StandardError => e
  raise "Failed to load YAML file: #{e.message}"
end

LANG_MAP = {
  'en' => 0,
  'fr' => 1,
  'es' => 2,  # Example for adding more languages
  'de' => 3
}.freeze

def to_md(html)
  Kramdown::Document.new(html.to_s, html_to_native: true).to_kramdown
end

def uuidgen
  SecureRandom.uuid
end

def create_translation(details, lang)
  {
    'id' => uuidgen,
    'created' => DateTime.now.rfc3339,
    'updated' => DateTime.now.rfc3339,
    'is_main' => lang == 'en',
    'language' => "#{lang}-#{lang.upcase}",
    'status' => 'in-progress',
    'data' => {
      'title' => details['title'] || 'TODO: set title',
      'cvss' => details['cvssv3'].sub('3.0', '3.1') || 'N/A',
      'references' => details['references'] || 'N/A',
      'refid' => details.dig('customFields', 0, 'text') || 'N/A',
      'summary' => to_md(details['description']),
      'description' => to_md(details['observation']),
      'recommendation' => to_md(details['remediation'])
    }
  }
end

pwndoc_data.each do |pv|
  uuid_main = uuidgen
  sysreptor_data = {
    'format' => 'templates/v2',
    'id' => uuid_main,
    'created' => DateTime.now.rfc3339,
    'updated' => DateTime.now.rfc3339,
    'tags' => [pv['category']],
    'translations' => []
  }

  pv['details'].each do |details|
    LANG_MAP.each_key do |lang|
      next unless details['locale'] == lang

      sysreptor_data['translations'] << create_translation(details, lang)
    end
  end

  FileUtils.mkdir_p(sysreptor_folder)
  json_file = "#{sysreptor_folder}/#{uuid_main}.json"
  File.open(json_file, 'w') do |file|
    file.write(JSON.pretty_generate(sysreptor_data))
  end
  `tar czf #{sysreptor_folder}/#{uuid_main}.tar.gz --directory #{sysreptor_folder} #{uuid_main}.json`
end

# Global archive
`tar -czf #{sysreptor_folder}/all-vulns.tar.gz -C #{sysreptor_folder} $(find #{sysreptor_folder} -maxdepth 1 -type f -name "*.json" -printf "%f\n")`

puts "Process completed successfully."
