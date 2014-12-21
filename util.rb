module CardGames

  module Utility
    def self.condense_name(name)
      name.gsub(/^\w/, "").downcase
    end
  end

end
