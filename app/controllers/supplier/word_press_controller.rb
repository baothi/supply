class Supplier::WordPressController < Supplier::BaseController
  before_action :set_woocreadential, only: [:index,:update_ckcs,:update_keyapi,:update_product]
  before_action :connect_woo, only: [:index,:update_product]
  before_action :connet_api, only: [:update_product]
  require "uri"
  require "net/http"
  def index
    @woocommerce = @connect_woo.get("products").parsed_response
    @current_supplier = current_supplier.email
  end


  def update_ckcs
    unless current_supplier.woo_credential.present?
      woo = Spree::WooCredential.new
      woo.teamable_type = "Spree::Supplier"
      woo.teamable_id = current_supplier.id
      woo.save
    end
  end

  def update_keyapi
    puts 'Params: '.yellow
    puts woocreadential_params.inspect
    if @woo.update(woocreadential_params)
      flash[:notice] = 'Settings Updated'
      redirect_to supplier_word_press_update_ckcs_path
    end
  end

  def update_product
    # woo = JSON.parse(params[:woo_product])
    woo_id = params[:product_id]
    gettoken = "Bearer #{@response}"
    print("=================================================11111===",woo_id)
    url = URI("http://172.16.0.149:8899/api/v1.0/item/GetList")

    http = Net::HTTP.new(url.host, url.port);
    request = Net::HTTP::Post.new(url)
    request["Authorization"] = gettoken
    request["Content-Type"] = "application/json"
    request.body = "{\n\"QueryParam\": {\n\"PageNumber\": 1,\n\"PageSize\": 20,\n\"OrderBy\": \"Id\",\n\"OrderType\":\"DESC\"\n},\n\"VendorId\":20449,\n\"HubId\":18355\n}"

    response = http.request(request)
    response = JSON.parse(response.read_body)
    response = response['Data']
    puts response
    print("========================.parsed_response=============================")
    # url1 = "http://172.16.0.149:8899/api/v1.0/item/GetList"
    # params = {QueryParam: {
    #               PageNumber: 1,
    #               PageSize: 20,
    #               OrderBy: "Id",
    #               OrderType: "DESC"
    #             },
    #             VendorId: 20449,
    #             HubId: 18355}
    # headers = {Authorization: gettoken, content_type: :json}
    # request = RestClient.post(url1,params.to_json,headers)
    # response = JSON.parse(request)
    # response = response['Data']
    # print(response)
    # job = Spree::LongRunningJob.create(action_type: 'import',
    #                                  job_type: 'woocommerce',
    #                                  initiated_by: 'user',
    #                                  teamable_type: 'Spree::Supplier',
    #                                  teamable_id: current_supplier.id,
    #                                  supplier_id: current_supplier.id,
    #                                  option_1: woo['id'],
    #                                  option_2: woo['name'],
    #                                  option_3: woo['slug'],
    #                                  option_4: woo['permalink'],
    #                                  option_5: woo['description'],
    #                                  option_6: woo['sku'],
    #                                  option_7: woo['price'],
    #                                  option_8: woo['regular_price'],
    #                                  option_9: woo['sale_price'],
    #                                  option_10: woo['stock_quantity'],
    #                                  shopify_publish_status: woo['status'],
    #                                  array_option_1: woo['images'],
    #                                  array_option_2: woo['attributes'],
    #                                  array_option_3: woo['variations']
    #                                    )
    # ::WooCommerce::CreateProductFromWooCommerceJob.perform_later(job.internal_identifier)

    redirect_to supplier_word_press_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_woocreadential
      @woo = Spree::WooCredential.find_by(teamable_id: current_supplier.id)
    end

    def connect_woo
      @connect_woo = WooCommerce::API.new(
      @woo.store_url,@woo.consumer_key,@woo.consumer_secret,
      {wp_api: true,version: @woo.version})
    end

    def connet_api
      url = URI("http://172.16.0.149:8899/api/v1/user/generateToken?ClientId=9A46AF7E-CA54-4B0D-8934-2A373DAAE77E&ApiKey=d195gZZOwZ0D8WxQE6X63PpXVF6lL4fjU/8aHxgXHhg=")

      http = Net::HTTP.new(url.host, url.port);
      request = Net::HTTP::Get.new(url)

      response = http.request(request)
      response = JSON.parse(response.read_body)
      @response = response['Message']
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def woocreadential_params
      params.require(:woo_credential).permit(:store_url,:consumer_key,:consumer_secret,:teamable_type,:teamable_id,:version)
    end


end
