#!/usr/bin/env ruby
#
# Redirect output into a file called Airports.xml to get 
# picked up by the makefile
#
require 'json'
require 'bundler'
Bundler.require

# Or swap out for ARGV[1]
GEOJSON_FILE = 'Airports.geojson'

class Dictionary
  attr_accessor :xml
  
  def initialize
    @entries = []
    
    @xml = Builder::XmlMarkup.new(:indent => 2)
    @xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
  end
  
  def <<(entry)
    @entries << entry
  end
  
  def contents
    dict_attrs = {
      'xmlns'   => 'http://www.w3.org/1999/xhtml', #XML is the future, baby!
      'xmlns:d' => 'http://www.apple.com/DTDs/DictionaryService-1.0.rng'
    }
    @xml.tag!('d:dictionary', dict_attrs) do
      
      @xml.tag!('d:entry', 'id' => 'front_back_matter', 'd:title' => 'Front/Back Matter') do
        @xml.tag!('h1') { @xml.tag!('b') { @xml.text 'US Airports' }}
        @xml.tag!('h1') { @xml.text 'Front/Back Matter'}
        @xml.div 'Airports current as of September 2024'
      end

      @entries.each do |feature|
        @xml.tag!('d:entry', 'id' => feature.id, 'd:title' => "#{feature.name} (Airport)") do
          unless feature.ident.nil?
            @xml.tag!('d:index', {'d:value': feature.ident}) 
            @xml.tag!('d:index', {'d:value': feature.ident + " (Airport)", 'd:priority': 2})
          end
          unless feature.icao.nil?
            @xml.tag!('d:index', {'d:value': feature.icao, 'd:priority': 1})
            @xml.tag!('d:index', {'d:value': feature.icao + " (Airport)", 'd:priority': 2}) 
          end
          unless feature.name.nil?
            @xml.tag!('d:index', {'d:value': feature.name, 'd:priority': 3}) 
            feature.name.split(' ').each_with_index do |term, i|
              @xml.tag!('d:index', {'d:value': term, 'd:priority': 4 + i}) 
            end
          end

          # Add the header
          xml.div('d:priority' => '2') do
            xml.h1 "#{feature.name} (#{feature.ident})"
          end

          # This is usually the pronounciation section,
          # but we're mostly dealing with pseudo-initialisms here.
          xml.span(:class => 'syntax') do
            xml.span('d:pr' => 'US') do
              xml.text [feature.city, feature.state].join(', ').strip
            end
          end

          # Add the details
          xml.div do
            xml.dl do
              xml.dt 'Elevation'
              xml.dd feature.elev || '(Unknown)'
              xml.dt 'Location'
              xml.dd do 
                xml.text! feature.loc&.to_s.strip
                unless feature.loc.nil?
                  ll = [
                    feature.loc.lat.to_f,
                    feature.loc.lng.to_f
                  ]
                  xml.tag!('br')
                  xml.a(href: "http://maps.apple.com/?ll=#{ll.join(',')}") do
                    xml.text! "Map Link"
                  end
                end
              end
              xml.dt 'Ownership'
              xml.dd feature.private_use ? 'Private' : 'Public'
              
              if feature.mil != 'CIVIL'
                xml.dt 'Military'
                xml.dd feature.mil
              end
            end
          end
        end
      end
    end
    
    @xml
  end
end

class Entry
  attr_reader :id, :ident, :icao, :name, :city, :state, :loc, :elev, :mil, :opr, :private_use
  
  def initialize(attrs)
    case attrs['type']
    when 'Feature'
      props  = attrs['properties']
      @id    = props['GLOBAL_ID']
      @ident = props['IDENT']
      @icao  = props['ICAO_ID']
      @name  = props['NAME']&.strip
      @city  = props['SERVCITY']&.titleize&.strip
      @state = props['STATE']&.strip
      @elev  = props['ELEVATION']&.to_f
      @mil   = props['MIL_CODE']
      @opr   = props['OPERSTATUS']
      @private_use = props['PRIVATEUSE'] == 1

      # %latd-%latm-%lats%lath,%lngd-%lngm-%lngs%lngh
      # "176-38-32.9360W,51-53-00.8980N"
      begin
        ll = props['LATITUDE'] + ',' + props['LONGITUDE']
        llfmt = "%latd-%latm-%lats%lath,%lngd-%lngm-%lngs%lngh"
        @loc  = Geo::Coord.strpcoord ll, llfmt
      rescue ArgumentError
        @loc = Geo::Coord.parse_ll ll rescue nil
      end
    end
  end
end

# Build the document
#
geojson_data = JSON.parse(File.read(GEOJSON_FILE))
puts "Expected GeoJSON FeatureCollection" and exit unless geojson_data['type'] == 'FeatureCollection'

# There are several duplicate ICAO identifiers.
# We could use a set here, or merge entries, etc.
#
dict = Dictionary.new
geojson_data['features'].each do |feature|
  dict << Entry.new(feature)
end

puts dict.contents.target!