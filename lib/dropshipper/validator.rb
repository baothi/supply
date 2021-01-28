module Dropshipper
  class Validator
    # max_length = maximum length
    # min_length = minimum length
    # exact_length = exact length
    # allow_special_char = are non-alpha numerics allowed? takes in argument
    #       e.g. allow_special_char=true,*,^,$,%
    # required = Ensures required
    # inclusion = Takes in comma separated list
    # regular_expression = NOT YET IMPLEMENTED
    # alpha_numeric = Allows Alpha Numeric
    # alpha_only = Allows Alpha Only
    # numeric - only accepts true.
    # exclusion = Takes in comma separated list.
    # no_space = No Space Allowed
    # begins_with - NOT YET IMPLEMENTED
    # ends_with - NOT YET IMPLEMENTED
    # contains - NOT YET IMPLEMENTED
    # valid_upc - NOT YET IMPLEMENTED
    # valid_ean - NOT YET IMPLEMENTED
    # valid_us_postal_code - NOT YET IMPLEMENTED
    # valid_ca_postal_code - NOT YET IMPLEMENTED
    # valid_postal_code - NOT YET IMPLEMENTED
    #         e.g. us, canada, gb
    # validate_state_short_code - NOT YET IMPLEMENTED
    # valid_html - NOT YET IMPLEMENTED
    # valid_credit_card - NOT YET IMPLEMENTED
    #         e.g. all, mastercard, visa, amex, discover

    def self.validate_constraints(rules)
      comma_count = rules.scan(/"/).count
      raise 'Invalid Rules Format' if comma_count.odd?
    end

    def self.split_rules(rules)
      hsh = {}
      rules = rules.split('|')
      rules.each do |rule|
        rule_name, rule_value = rule.split('=')
        hsh[rule_name.to_s.strip] = rule_value.to_s.strip
      end
      hsh
    end

    def self.validate(contents, rules, _filter = nil)
      if contents.nil? || rules.nil?
        return ResponseObject.
               failure_response_object('Invalid Rule or Contents detected.')
      end

      # puts "Looking to validate: #{contents} againsts #{rules}"

      begin
        rules_hash = split_rules(rules)

        rules_hash.each do |rule_name, rule_value|
          msg = "Failed Validation: #{rule_name}: #{rule_value}"
          return ResponseObject.failure_response_object(msg) unless
              public_send(rule_name, contents, rule_value, rules_hash)
        end
        msg = 'Passed all validations'
        ResponseObject.
          success_response_object(msg)
      rescue => ex
        msg = "Invalid Rules Detected: #{rules}: #{ex}"
        puts msg.red
        return ResponseObject.failure_response_object(msg)
      end
    end

    # True means that all values must be numeric i.e. that this is a valid number or float
    # False means that it cannot be all numeric

    def self.numeric(val, constraints, _opts = {})
      begin
        if constraints == 'true'
          Float(val) # This will raise an error if invalid
          return true
        elsif constraints == 'false'
          !val.number_only?
        end
      rescue
        return false
      end
    end

    def self.max_length(val, constraints, _opts = {})
      constraints = constraints.to_i
      val.length < constraints
    end

    def self.exact_length(val, constraints, _opts = {})
      constraints = constraints.to_i
      val.length == constraints
    end

    def self.min_length(val, constraints, _opts = {})
      constraints = constraints.to_i
      val.length >= constraints
    end

    def self.return_real_character(name)
      case name
      when 'percent'
        '%'
      when 'comma'
        ','
      when 'dash'
        '-'
      when 'pipe'
        '|'
      when 'back_slash'
        '\\'
      when 'forward_slash'
        '/'
      when 'equals', 'equal'
        return '='
      else
        name
      end
    end

    def self.strip_special_characters(val, special_chars)
      return val if special_chars.count.zero?

      cloned_val = val.dup.to_s
      special_chars.each do |char|
        cloned_val.gsub!(return_real_character(char), '')
      end
      # stripped = val.to_s.delete(special_chars.join(''))
      cloned_val
    end

    # allow_special_char=true -> means that we are allowing all special characters
    # allow_special_char=false -> means we are not allowing ANY special characters
    # allow_special_char=false,+,* -> means that we are ONLY allowing + and * as special characters

    def self.allow_special_char(val, constraints, _opts = {})
      # No need to check further
      return true if constraints.starts_with?('true')

      # Now we need to check for case when special characters aren't allowed
      # except for the other arguments
      valid_chars = constraints.split(',')
      special_chars = valid_chars.slice(1, valid_chars.length)
      allow_special_chars = valid_chars[0]
      raise 'Invalid Value' unless allow_special_chars == 'false'

      # Check to see if we have special characters to check
      num_special_chars = special_chars.size
      return val.alpha? if num_special_chars.zero?

      val = strip_special_characters(val, special_chars)
      val.alpha?
    end

    def self.required(val, constraints, _opts = {})
      if constraints == 'true'
        val.present?
      else
        true
      end
    end

    def self.alpha_numeric(val, _constraints, _opts = {})
      val.alpha?
    end

    def self.inclusion(val, constraints, _opts = {})
      constraints = constraints.split(',')
      constraints.each do |constraint|
        return true if val == constraint.to_s.strip
      end
      false
    end

    def self.exclusion(val, constraints, _opts = {})
      constraints = constraints.split(',')
      constraints.each do |constraint|
        return false if val == constraint.to_s.strip
      end
      true
    end

    def self.no_space(val, constraints, _opts = {})
      if constraints == 'true'
        !val.include?(' ')
      elsif constraints == 'false'
        val.include?(' ')
      else
        raise 'Invalid Value'
      end
    end

    def self.regular_expression(val, constraints, _opts = {})
      # puts "Constraints: #{constraints}"
      constraints = Regexp.new(constraints)
      puts "#{val.match(constraints)}"
      val.match(constraints)
    end

    # Commonly Used Validations
    REQUIRED_TRUE = 'required=true'.freeze
    REQUIRED_FALSE = 'required=false'.freeze
    NUMERIC_TRUE = 'numeric=true'.freeze
    NUMERIC_FALSE = 'numeric=false'.freeze
    REQUIRED_AND_NUMERIC = "#{REQUIRED_TRUE}|#{NUMERIC_TRUE}".freeze
    # Special characters
    # 'allow_special_char=true|special_chars=3,3,3,2,2,21,1,1'
    ALLOW_SPECIAL_CHAR_TRUE = 'allow_special_char=true'.freeze
    ALLOW_SPECIAL_CHAR_FALSE = 'allow_special_char=false'.freeze
    ALLOW_SPECIAL_CHAR_DASHES_ONLY = 'allow_special_char=false,dash'.freeze
    REQUIRED_AND_ALLOW_SPECIAL_CHAR_DASHES_ONLY =
      "#{REQUIRED_TRUE}|#{ALLOW_SPECIAL_CHAR_DASHES_ONLY}".freeze
    # TODO: Move this to DB
    PACSUN_WHITE_LISTED_CHARACTERS =
      'allow_special_char=false'\
      ',.,*,!,;,:,+,(,),comma,dash,back_slash,forward_slash,equals,equal,$,_,#,",&'.freeze
    PACSUN_WHITE_LISTED_FOR_HTML = "#{PACSUN_WHITE_LISTED_CHARACTERS},<,>,percent".freeze
  end
end
