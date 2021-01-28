module ApplicationHelper
  PHONE_NUMBER_VALIDATOR_REGEX = /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/

  def referrals_path_for_role(teamable)
    case teamable.class.name
    when 'Spree::Retailer'
      retailer_referrals_path
    when 'Spree::Supplier'
      supplier_referrals_path
    else
      root_path
    end
  end

  def add_referrals_path_for_role(teamable)
    case teamable.class.name
    when 'Spree::Retailer'
      retailer_add_referral_path
    when 'Spree::Supplier'
      supplier_add_referral_path
    else
      root_path
    end
  end

  def inner_menu_html(inner_menu:,
                      section:,
                      link:,
                      title:,
                      secret: false,
                      true_user:,
                      new_window: false)
    return if secret && (true_user.blank? || !true_user.hingeto_user?)

    "<li class=\"site-menu-item #{check_if_active_css(inner_menu, section)} %>\">"\
    "<a href=\"#{link}\" #{open_in_new_window_html(new_window)}>"\
    "<span class=\"site-menu-title\">#{title}</span>"\
    '</a></li>'.html_safe
  end

  def open_in_new_window_html(new_window)
    'target="blank"' if new_window
  end

  # For showing which retailers, the supplier has access to
  def show_licensed_suppliers_access_html(retailer)
    results = retailer.licensed_suppliers_list
    access = results[0]
    no_access = results[1]
    'Visible to Hingeto Admins Only: At this time, this retailer has access to the following '\
    "licensed supppliers: #{access.map(&:name).join(',')} "\
    "but does not have access to #{no_access.map(&:name).join(',')} <br/><br/>".html_safe
  end

  def subregions_of_us
    countries = Carmen::Country.all.select { |c| %w(US).include?(c.code) }
    # get subregions and sort in alphabetical order
    countries.map(&:subregions).flatten.sort_by(&:name)
  end

  def subregions_of_us_code
    countries = Carmen::Country.all.select { |c| %w(US).include?(c.code) }
    # get subregions and sort in alphabetical order
    countries.map(&:subregions).flatten.sort_by(&:name)
  end

  def check_if_active_css(option1, option2)
    option1 == option2 ? 'active' : ''
  end

  def check_if_open_css(option1, option2)
    option1 == option2 ? 'open' : ''
  end

  def fulfillment_rate(percentage)
    html = ''
    html << if percentage >= 90
              "<span class='text-success text-semibold'>#{percentage}%</span>"
            elsif percentage < 90 && percentage > 50
              "<span class='text-warning text-semibold'>#{percentage}%</span>"
            else
              "<span class='text-danger text-semibold'>#{percentage}%</span>"
            end
    html.html_safe
  end

  def return_rate(percentage)
    html = ''
    html << if percentage <= 10
              "<span class='text-success text-semibold'>#{percentage}%</span>"
            elsif percentage > 10 && percentage < 30
              "<span class='text-warning text-semibold'>#{percentage}%</span>"
            else
              "<span class='text-danger text-semibold'>#{percentage}%</span>"
            end
    html.html_safe
  end

  def days_to_ship(num_days)
    html = ''
    html << if num_days > 2
              "<span class='text-success text-semibold'>#{num_days}</span>"
            elsif num_days <= 2 && num_days.positive?
              "<span class='text-warning text-semibold'>#{num_days}</span>"
            else
              "<span class='text-danger text-semibold'>#{num_days}</span>"
            end
    html.html_safe
  end

  def avg_shipping_time(num_days)
    html = ''
    html << if num_days < 3
              "<span class='text-success text-semibold'>#{num_days}</span>"
            elsif num_days >= 3 && num_days <= 7
              "<span class='text-warning text-semibold'>#{num_days}</span>"
            else
              "<span class='text-danger text-semibold'>#{num_days}</span>"
            end
    html.html_safe
  end

  def shipping_status(status)
    html = ''
    html << if status == 'Shipped'
              '<span class="tag tag-success">Shipped</span>'
            else
              '<span class="tag tag-danger">Not Shipped</span>'
            end
    html.html_safe
  end

  def payment_status(status)
    html = ''
    html << if status == 'Paid'
              '<input type="radio" id="inputRadiosDisabled" name="inputRadiosDisabled" disabled="">
              <label for="inputRadiosDisabled">Paid</label>'
            else
              '<input type="radio" id="inputRadiosDisabledChecked" name="inputRadiosDisabledChecked"
              disabled="" checked=""><label for="inputRadiosDisabledChecked">Paid</label>'
            end
    html.html_safe
  end

  def fulfillment_status(status)
    html = ''
    html << if status == 'Fulfilled'
              '<span class="tag tag-success">Fulfilled</span>'
            else
              '<span class="tag tag-danger">Unfulfilled</span>'
            end
    html.html_safe
  end

  def invoice_status(status)
    html = ''
    html << case status.to_s.downcase
            when 'approved' then %(<span class='tag tag-success'>#{status.to_s.capitalize}</span>)
            when 'scheduled' then %(<span class='tag tag-info'>#{status.to_s.capitalize}</span>)
            when 'sent' then %(<span class='tag tag-success'>#{status.to_s.capitalize}</span>)
            when 'void' then %(<span class='tag tag-danger'>#{status.to_s.capitalize}</span>)
            when 'closed' then %(<span class='tag tag-default'>#{status.to_s.capitalize}</span>)
            when 'draft' then %(<span class='tag tag-warning'>#{status.to_s.capitalize}</span>)
            else %(<span class='tag tag-info'>#{status.to_s.capitalize}</span>)
            end
    html.html_safe
  end

  def symbol_to_string(symbol)
    symbol.to_s.split('_').map(&:capitalize).join(' ')
  end

  def product_status_from_symbol(symbol)
    symbol.to_s.split('_').map(&:capitalize).join(' ')
  end

  def product_status(status)
    html = ''
    html << case status.to_s.downcase
            when 'live' then %(<span class='tag tag-success'>#{status.to_s.titleize}</span>)
            when 'pending' then %(<span class='tag tag-info'>#{status.to_s.titleize}</span>)
            when 'requires_attention'
              then %(<span class='tag tag-danger'>#{status.to_s.titleize}</span>)
            when 'declined' then %(<span class='tag tag-danger'>#{status.to_s.titleize}</span>)
            when 'inactive' then %(<span class='tag tag-default'>#{status.to_s.titleize}</span>)
            when 'draft' then %(<span class='tag tag-warning'>#{status.to_s.titleize}</span>)
            else %(<span class='tag tag-info'>#{status.to_s.titleize}</span>)
            end
    html.html_safe
  end

  def colored_dollar_amount(amount)
    html = ''
    html << if !amount.blank? && amount.delete('$').to_f.positive?
              "<span class='text-success text-semibold'>#{amount}</span>"
            else
              "<span class='text-danger text-semibold'>#{amount}</span>"
            end
    html.html_safe
  end

  def permited_url_params
    params.permit(:utf8, :sort, :search_field, :search_value, :page)
  end

  def convert_model_validation_errors_to_sentence(model, include_attribute = true)
    if include_attribute
      message = model.errors.full_messages.join('. ') unless model.nil?
    else
      message = model.errors.values.join('. ') unless model.nil?
    end
    message
  end
end
