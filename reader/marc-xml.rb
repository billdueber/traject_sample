require 'traject'
require 'traject/marc_reader'


settings do
  provide "reader_class_name", "Traject::MarcReader"
  provide "marc_source.type", "xml"
end
