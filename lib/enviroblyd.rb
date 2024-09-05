# frozen_string_literal: true

module Enviroblyd
end

# require "active_support"
# require "active_support/core_ext"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "imds" => "IMDS"
)
loader.setup
loader.eager_load
