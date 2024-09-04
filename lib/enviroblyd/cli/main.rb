# frozen_string_literal: true

class Enviroblyd::Cli::Main < Enviroblyd::Base
  desc "version", "Show version"
  def version
    puts Enviroblyd::VERSION
  end
end
