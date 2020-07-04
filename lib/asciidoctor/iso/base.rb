require "date"
require "nokogiri"
require "json"
require "pathname"
require "open-uri"
require "isodoc"
require "fileutils"
require 'asciidoctor/iso/macros'

module Asciidoctor
  module ISO
    class Converter < Standoc::Converter
      XML_ROOT_TAG = "iso-standard".freeze
      XML_NAMESPACE = "https://www.metanorma.org/ns/iso".freeze

      Asciidoctor::Extensions.register do
        inline_macro Asciidoctor::Iso::TermRefInlineMacro
      end

      def html_converter(node)
        IsoDoc::Iso::HtmlConvert.new(html_extract_attributes(node))
      end

      def html_converter_alt(node)
        IsoDoc::Iso::HtmlConvert.new(html_extract_attributes(node).
                                     merge(alt: true))
      end

      def doc_converter(node)
        IsoDoc::Iso::WordConvert.new(doc_extract_attributes(node))
      end

      def pdf_converter(node)
        return nil if node.attr("no-pdf")
        IsoDoc::Iso::PdfConvert.new(doc_extract_attributes(node))
      end

      def sts_converter(node)
        return nil if node.attr("no-pdf")
        IsoDoc::Iso::StsConvert.new(html_extract_attributes(node))
      end

      def presentation_xml_converter(node)
        IsoDoc::Iso::PresentationXMLConvert.new(html_extract_attributes(node))
      end

      def init(node)
        super
        @amd = %w(amendment technical-corrigendum).include? node.attr("doctype")
      end

      def outputs(node, ret)
          File.open(@filename + ".xml", "w:UTF-8") { |f| f.write(ret) }
          presentation_xml_converter(node).convert(@filename + ".xml")
          html_converter_alt(node).convert(@filename + ".presentation.xml", 
                                           nil, false, "#{@filename}_alt.html")
          html_converter(node).convert(@filename + ".presentation.xml", 
                                       nil, false, "#{@filename}.html")
          doc_converter(node).convert(@filename + ".presentation.xml", 
                                      nil, false, "#{@filename}.doc")
          pdf_converter(node)&.convert(@filename + ".presentation.xml", 
                                       nil, false, "#{@filename}.pdf")
          #sts_converter(node)&.convert(@filename + ".xml")
      end

      def load_yaml(lang, script)
        y = if @i18nyaml then YAML.load_file(@i18nyaml)
            elsif lang == "en"
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
            elsif lang == "fr"
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-fr.yaml"))
            elsif lang == "zh" && script == "Hans"
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-zh-Hans.yaml"))
            else
              YAML.load_file(File.join(File.dirname(__FILE__), "i18n-en.yaml"))
            end
        super.merge(y)
      end
    end
  end
end
