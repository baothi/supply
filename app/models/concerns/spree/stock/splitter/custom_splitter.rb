module Spree::Stock::Splitter
  class CustomSplitter < Spree::Stock::Splitter::Base
    def split(packages)
      split_packages = []
      packages.each do |package|
        package.contents.each do |item|
          split_packages << build_package([item])
        end
      end
      return_next split_packages
    end
  end
end
