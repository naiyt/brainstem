module Brainstem
  class InclusionParser
    class ParseError < StandardError
    end

    def self.parse(string)
      return {} if string.blank?

      depth = 0
      current_token = ''
      stack = []
      inclusions = {}
      string.each_char.with_index do |character, index|
        case character
          when ' '
            # ignore
          when '('
            raise ParseError.new("Missing token before parenthesis at position #{index}: #{string[0..index]}") if current_token.blank?
            inclusions[current_token] = {}
            stack << inclusions
            inclusions = inclusions[current_token]
            current_token = ''
          when ')'
            inclusions[current_token] = {} if current_token.present?
            current_token = ''
            inclusions = stack.pop
            raise ParseError.new("Too many closing parenthesis at position #{index}: #{string[0..index]}") if inclusions.nil?
          when ','
            inclusions[current_token] = {} if current_token.present?
            current_token = ''
          else
            current_token += character
        end
      end

      inclusions[current_token] = {} if current_token.present?

      raise ParseError.new("Missing closing parenthesis: #{string}") if stack.length > 0

      inclusions
    end
  end
end
